// vite.config.js
import { defineConfig } from "file:///D:/Dropbox/projects/midi_cs/controller_v2/VSTMastrCtrl/mastrctrl/plugin/ui/node_modules/vite/dist/node/index.js";
import vue from "file:///D:/Dropbox/projects/midi_cs/controller_v2/VSTMastrCtrl/mastrctrl/plugin/ui/node_modules/@vitejs/plugin-vue/dist/index.mjs";
var vite_config_default = defineConfig({
  plugins: [vue()],
  server: {
    port: 3e3,
    host: "0.0.0.0",
    // This allows access from any device on the network
    cors: true
  },
  build: {
    outDir: "dist",
    assetsDir: "assets",
    rollupOptions: {
      output: {
        entryFileNames: "js/[name].js",
        chunkFileNames: "js/[name].js",
        assetFileNames: (assetInfo) => {
          if (assetInfo.name.endsWith(".css")) {
            return "css/[name][extname]";
          }
          return "assets/[name][extname]";
        }
      }
    }
  }
});
export {
  vite_config_default as default
};
//# sourceMappingURL=data:application/json;base64,ewogICJ2ZXJzaW9uIjogMywKICAic291cmNlcyI6IFsidml0ZS5jb25maWcuanMiXSwKICAic291cmNlc0NvbnRlbnQiOiBbImNvbnN0IF9fdml0ZV9pbmplY3RlZF9vcmlnaW5hbF9kaXJuYW1lID0gXCJEOlxcXFxEcm9wYm94XFxcXHByb2plY3RzXFxcXG1pZGlfY3NcXFxcY29udHJvbGxlcl92MlxcXFxWU1RNYXN0ckN0cmxcXFxcbWFzdHJjdHJsXFxcXHBsdWdpblxcXFx1aVwiO2NvbnN0IF9fdml0ZV9pbmplY3RlZF9vcmlnaW5hbF9maWxlbmFtZSA9IFwiRDpcXFxcRHJvcGJveFxcXFxwcm9qZWN0c1xcXFxtaWRpX2NzXFxcXGNvbnRyb2xsZXJfdjJcXFxcVlNUTWFzdHJDdHJsXFxcXG1hc3RyY3RybFxcXFxwbHVnaW5cXFxcdWlcXFxcdml0ZS5jb25maWcuanNcIjtjb25zdCBfX3ZpdGVfaW5qZWN0ZWRfb3JpZ2luYWxfaW1wb3J0X21ldGFfdXJsID0gXCJmaWxlOi8vL0Q6L0Ryb3Bib3gvcHJvamVjdHMvbWlkaV9jcy9jb250cm9sbGVyX3YyL1ZTVE1hc3RyQ3RybC9tYXN0cmN0cmwvcGx1Z2luL3VpL3ZpdGUuY29uZmlnLmpzXCI7aW1wb3J0IHsgZGVmaW5lQ29uZmlnIH0gZnJvbSAndml0ZSdcclxuaW1wb3J0IHZ1ZSBmcm9tICdAdml0ZWpzL3BsdWdpbi12dWUnXHJcblxyXG5leHBvcnQgZGVmYXVsdCBkZWZpbmVDb25maWcoe1xyXG4gIHBsdWdpbnM6IFt2dWUoKV0sXHJcbiAgc2VydmVyOiB7XHJcbiAgICBwb3J0OiAzMDAwLFxyXG4gICAgaG9zdDogJzAuMC4wLjAnLCAvLyBUaGlzIGFsbG93cyBhY2Nlc3MgZnJvbSBhbnkgZGV2aWNlIG9uIHRoZSBuZXR3b3JrXHJcbiAgICBjb3JzOiB0cnVlXHJcbiAgfSxcclxuICBidWlsZDoge1xyXG4gICAgb3V0RGlyOiAnZGlzdCcsXHJcbiAgICBhc3NldHNEaXI6ICdhc3NldHMnLFxyXG4gICAgcm9sbHVwT3B0aW9uczoge1xyXG4gICAgICBvdXRwdXQ6IHtcclxuICAgICAgICBlbnRyeUZpbGVOYW1lczogJ2pzL1tuYW1lXS5qcycsXHJcbiAgICAgICAgY2h1bmtGaWxlTmFtZXM6ICdqcy9bbmFtZV0uanMnLFxyXG4gICAgICAgIGFzc2V0RmlsZU5hbWVzOiAoYXNzZXRJbmZvKSA9PiB7XHJcbiAgICAgICAgICBpZiAoYXNzZXRJbmZvLm5hbWUuZW5kc1dpdGgoJy5jc3MnKSkge1xyXG4gICAgICAgICAgICByZXR1cm4gJ2Nzcy9bbmFtZV1bZXh0bmFtZV0nXHJcbiAgICAgICAgICB9XHJcbiAgICAgICAgICByZXR1cm4gJ2Fzc2V0cy9bbmFtZV1bZXh0bmFtZV0nXHJcbiAgICAgICAgfVxyXG4gICAgICB9XHJcbiAgICB9XHJcbiAgfVxyXG59KVxyXG4iXSwKICAibWFwcGluZ3MiOiAiO0FBQWthLFNBQVMsb0JBQW9CO0FBQy9iLE9BQU8sU0FBUztBQUVoQixJQUFPLHNCQUFRLGFBQWE7QUFBQSxFQUMxQixTQUFTLENBQUMsSUFBSSxDQUFDO0FBQUEsRUFDZixRQUFRO0FBQUEsSUFDTixNQUFNO0FBQUEsSUFDTixNQUFNO0FBQUE7QUFBQSxJQUNOLE1BQU07QUFBQSxFQUNSO0FBQUEsRUFDQSxPQUFPO0FBQUEsSUFDTCxRQUFRO0FBQUEsSUFDUixXQUFXO0FBQUEsSUFDWCxlQUFlO0FBQUEsTUFDYixRQUFRO0FBQUEsUUFDTixnQkFBZ0I7QUFBQSxRQUNoQixnQkFBZ0I7QUFBQSxRQUNoQixnQkFBZ0IsQ0FBQyxjQUFjO0FBQzdCLGNBQUksVUFBVSxLQUFLLFNBQVMsTUFBTSxHQUFHO0FBQ25DLG1CQUFPO0FBQUEsVUFDVDtBQUNBLGlCQUFPO0FBQUEsUUFDVDtBQUFBLE1BQ0Y7QUFBQSxJQUNGO0FBQUEsRUFDRjtBQUNGLENBQUM7IiwKICAibmFtZXMiOiBbXQp9Cg==
