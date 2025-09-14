"""
Google Generative AI client singleton for Gemini caching integration.

This module provides a singleton instance of the Google Generative AI client
for use with explicit caching features in Gemini 2.5 Pro.
"""

import os
import google.generativeai as genai
from typing import Optional
from core.utils.logger import logger
from core.utils.config import config


class GeminiClient:
    """Singleton wrapper for Google Generative AI client."""
    
    _instance: Optional['GeminiClient'] = None
    _client: Optional[genai.GenerativeModel] = None
    
    def __new__(cls) -> 'GeminiClient':
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance
    
    def __init__(self):
        if not hasattr(self, '_initialized'):
            self._initialize_client()
            self._initialized = True
    
    def _initialize_client(self) -> None:
        """Initialize the Google Generative AI client."""
        api_key = config.GEMINI_API_KEY
        if not api_key:
            logger.warning("GEMINI_API_KEY not found in environment variables")
            return
        
        try:
            genai.configure(api_key=api_key)
            # Create a default model instance for caching operations
            self._client = genai.GenerativeModel('gemini-2.5-pro')
            logger.debug("Google Generative AI client initialized successfully")
        except Exception as e:
            logger.error(f"Failed to initialize Google Generative AI client: {e}")
            self._client = None
    
    @property
    def client(self) -> Optional[genai.GenerativeModel]:
        """Get the configured GenerativeModel instance."""
        return self._client
    
    def get_model(self, model_name: str = "gemini-2.5-pro") -> Optional[genai.GenerativeModel]:
        """Get a GenerativeModel instance for the specified model."""
        if not self._client:
            return None
        
        try:
            return genai.GenerativeModel(model_name)
        except Exception as e:
            logger.error(f"Failed to get model {model_name}: {e}")
            return None
    
    def is_available(self) -> bool:
        """Check if the Gemini client is available and configured."""
        return self._client is not None


# Global singleton instance
gemini_client = GeminiClient()
