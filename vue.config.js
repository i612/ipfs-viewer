process.env.VUE_APP_VERSION = process.env.COMMIT_REF || '';
process.env.VUE_APP_PRODUCTION = process.env.NODE_ENV === 'production';
