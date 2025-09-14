"""
Gemini explicit cache management service.

This module provides functionality to create and manage explicit caches
for Gemini 2.5 Pro to optimize token usage for stable prefixes.
"""

import hashlib
import json
import time
from typing import Dict, List, Any, Optional, Tuple
from dataclasses import dataclass
import google.generativeai as genai
from core.utils.logger import logger
from core.services.geminiClient import gemini_client


@dataclass
class PrefixCacheKey:
    """Key for identifying cache entries."""
    model: str
    prefix_hash: str


class GeminiCacheService:
    """Service for managing Gemini explicit caches."""
    
    def __init__(self):
        self._cache_name_map: Dict[str, Tuple[str, float]] = {}  # hash -> (cache_name, expires_at)
        self._default_ttl = 86400  # 24 hours in seconds
        self._cache_expiry_buffer = 300  # 5 minutes buffer before TTL expires
    
    def _compute_prefix_hash(
        self, 
        model: str, 
        system_instruction: Optional[str] = None,
        tools: Optional[List[Dict[str, Any]]] = None,
        static_docs: Optional[List[str]] = None
    ) -> str:
        """Compute a stable SHA-256 hash for the prefix content."""
        content_parts = [model]
        
        if system_instruction:
            content_parts.append(f"system:{system_instruction}")
        
        if tools:
            # Normalize tool schemas for consistent hashing
            normalized_tools = []
            for tool in tools:
                if isinstance(tool, dict):
                    # Sort keys for consistent ordering
                    normalized_tool = {k: v for k, v in sorted(tool.items())}
                    normalized_tools.append(json.dumps(normalized_tool, sort_keys=True))
            content_parts.append(f"tools:{json.dumps(normalized_tools, sort_keys=True)}")
        
        if static_docs:
            content_parts.append(f"docs:{json.dumps(sorted(static_docs), sort_keys=True)}")
        
        # Create hash from normalized content
        content_str = "|".join(content_parts)
        return hashlib.sha256(content_str.encode('utf-8')).hexdigest()
    
    def _is_cache_valid(self, cache_key: str) -> bool:
        """Check if a cache entry is still valid."""
        if cache_key not in self._cache_name_map:
            return False
        
        _, expires_at = self._cache_name_map[cache_key]
        return time.time() < expires_at
    
    def _get_cached_name(self, cache_key: str) -> Optional[str]:
        """Get the cached name if it's still valid."""
        if self._is_cache_valid(cache_key):
            cache_name, _ = self._cache_name_map[cache_key]
            return cache_name
        return None
    
    def _store_cache_name(self, cache_key: str, cache_name: str, ttl_seconds: int) -> None:
        """Store the cache name with expiration."""
        expires_at = time.time() + ttl_seconds - self._cache_expiry_buffer
        self._cache_name_map[cache_key] = (cache_name, expires_at)
        logger.debug(f"Stored cache name {cache_name} for key {cache_key}, expires at {expires_at}")
    
    async def get_or_create_prefix_cache(
        self,
        model: str,
        contents: List[Any],
        system_instruction: Optional[str] = None,
        tools: Optional[List[Dict[str, Any]]] = None,
        static_docs: Optional[List[str]] = None,
        ttl_seconds: int = None
    ) -> Optional[str]:
        """
        Get or create a prefix cache for the given content.
        
        Args:
            model: The Gemini model name
            contents: List of content parts for the cache
            system_instruction: Optional system instruction
            tools: Optional list of tool definitions
            static_docs: Optional list of static documentation
            ttl_seconds: Cache TTL in seconds (default: 24 hours)
            
        Returns:
            Cache name if successful, None otherwise
        """
        if not gemini_client.is_available():
            logger.warning("Gemini client not available, skipping cache creation")
            return None
        
        if ttl_seconds is None:
            ttl_seconds = self._default_ttl
        
        # Compute cache key
        cache_key = self._compute_prefix_hash(
            model, system_instruction, tools, static_docs
        )
        
        # Check if we have a valid cached name
        cached_name = self._get_cached_name(cache_key)
        if cached_name:
            logger.debug(f"Using existing cache {cached_name} for key {cache_key}")
            return cached_name
        
        try:
            # Create new cache
            logger.debug(f"Creating new cache for model {model} with key {cache_key}")
            
            # Prepare cache configuration
            cache_config = {
                "contents": contents,
                "ttl": f"{ttl_seconds}s",
                "display_name": f"prefix-cache-{cache_key[:8]}"
            }
            
            if system_instruction:
                cache_config["system_instruction"] = system_instruction
            
            # Create the cache using the Gemini API
            cache = genai.caches.create(
                model=model,
                config=cache_config
            )
            
            cache_name = cache.name
            self._store_cache_name(cache_key, cache_name, ttl_seconds)
            
            logger.info(f"Created new Gemini cache {cache_name} for model {model}")
            return cache_name
            
        except Exception as e:
            logger.error(f"Failed to create Gemini cache: {e}", exc_info=True)
            return None
    
    async def invalidate_cache(self, cache_name: str) -> bool:
        """Invalidate a specific cache by name."""
        try:
            genai.caches.delete(name=cache_name)
            logger.info(f"Invalidated cache {cache_name}")
            
            # Remove from our local mapping
            keys_to_remove = [
                key for key, (name, _) in self._cache_name_map.items() 
                if name == cache_name
            ]
            for key in keys_to_remove:
                del self._cache_name_map[key]
            
            return True
        except Exception as e:
            logger.error(f"Failed to invalidate cache {cache_name}: {e}")
            return False
    
    def get_cache_stats(self) -> Dict[str, Any]:
        """Get statistics about cached entries."""
        current_time = time.time()
        valid_caches = 0
        expired_caches = 0
        
        for _, (_, expires_at) in self._cache_name_map.items():
            if current_time < expires_at:
                valid_caches += 1
            else:
                expired_caches += 1
        
        return {
            "total_caches": len(self._cache_name_map),
            "valid_caches": valid_caches,
            "expired_caches": expired_caches,
            "cache_keys": list(self._cache_name_map.keys())
        }
    
    def log_cache_stats(self) -> None:
        """Log current cache statistics."""
        stats = self.get_cache_stats()
        logger.info(f"📊 Gemini Cache Stats - Total: {stats['total_caches']}, "
                   f"Valid: {stats['valid_caches']}, Expired: {stats['expired_caches']}")
        
        if stats['valid_caches'] > 0:
            logger.info(f"🔑 Active cache keys: {', '.join(stats['cache_keys'][:3])}"
                       f"{'...' if len(stats['cache_keys']) > 3 else ''}")


# Global singleton instance
gemini_cache_service = GeminiCacheService()
