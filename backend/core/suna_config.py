from core.prompts.prompt import SYSTEM_PROMPT

# Suna default configuration - simplified and centralized
SUNA_CONFIG = {
    "name": "Iris",
    "description": "Suna is your AI assistant with access to various tools and integrations to help you with tasks across domains.",
    "avatar": "🌞",
    "avatar_color": "#F59E0B",
    "model": "google/gemini-2.5-pro",
    "system_prompt": SYSTEM_PROMPT,
    "configured_mcps": [],
    "custom_mcps": [],
    "agentpress_tools": {
        "sb_shell_tool": True,
        "sb_files_tool": True,
        "sb_deploy_tool": True,
        "sb_expose_tool": True,
        "web_search_tool": True,
        "sb_vision_tool": True,
        "sb_docs_tool": True,
        "sb_image_edit_tool": True,
        "sb_presentation_outline_tool": True,
        "sb_presentation_tool": True,
        "sb_sheets_tool": True,
        "browser_tool": True,
        "data_providers_tool": True,
        "sb_web_dev_tool": True,
        "agent_config_tool": True,
        "agent_creation_tool": True,
        "mcp_search_tool": True,
        "credential_profile_tool": True,
        "workflow_tool": True,
        "trigger_tool": True
    },
    "is_default": True
}
