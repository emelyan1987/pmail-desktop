import plugin from '../package.json'

export const PLUGIN_NAME = plugin.title
export const PLUGIN_ID = plugin.appId[PlanckEnv.config.get("env")];
export const PLUGIN_URL = plugin.serverUrl[PlanckEnv.config.get("env")];
