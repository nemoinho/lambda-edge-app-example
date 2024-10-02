import { cpSync } from 'node:fs';

// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2024-04-03',
  devtools: { enabled: true },
  nitro: {
    preset: 'aws_lambda',
  },
   hooks: {
    'nitro:build:public-assets': (nitro) => {
      // copy email templates to .output/server/emails
      const targetDir = nitro.options.output.serverDir;
      cpSync('./lambda@edge', targetDir, { recursive: true });
    }
  }
})
