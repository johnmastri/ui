import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../stores/display_store.dart';
import '../stores/parameter_store.dart';
import '../stores/settings_store.dart';
import '../stores/websocket_store.dart';
import '../theme/theme_manager.dart';
import '../widgets/knob_widget.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top navigation bar
            _buildTopNavigation(context),
            
            // Main display area
            Expanded(
              child: _buildMainDisplay(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavigation(BuildContext context) {
    return Consumer<DisplayStore>(
      builder: (context, displayStore, child) {
        return Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).appBarTheme.backgroundColor,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // View toggle buttons
              _buildViewToggleButtons(context, displayStore),
              
              const Spacer(),
              
              // Settings and theme buttons
              _buildActionButtons(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildViewToggleButtons(BuildContext context, DisplayStore displayStore) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildToggleButton(
          context,
          'VU Meter',
          displayStore.isVuMeterMode,
          () => displayStore.switchToVuMeter(),
        ),
        const SizedBox(width: 8),
        _buildToggleButton(
          context,
          'Knobs',
          displayStore.isKnobsMode,
          () => displayStore.switchToKnobs(),
        ),
      ],
    );
  }

  Widget _buildToggleButton(
    BuildContext context,
    String text,
    bool isActive,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive 
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surface,
        foregroundColor: isActive 
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(text),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // WebSocket status
        _buildWebSocketStatus(context),
        
        const SizedBox(width: 8),
        
        // Settings button
        IconButton(
          onPressed: () {
            context.read<SettingsStore>().openSettingsPanel();
          },
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
        ),
        
        const SizedBox(width: 8),
        
        // Theme toggle button
        IconButton(
          onPressed: () {
            context.read<SettingsStore>().nextTheme();
          },
          icon: const Icon(Icons.palette),
          tooltip: 'Toggle Theme',
        ),
      ],
    );
  }

  Widget _buildWebSocketStatus(BuildContext context) {
    return Consumer<WebSocketStore>(
      builder: (context, webSocketStore, child) {
        final themeExtension = Theme.of(context).extension<HardwareControllerThemeExtension>();
        
        Color statusColor;
        IconData statusIcon;
        
        if (webSocketStore.isConnected) {
          statusColor = themeExtension?.websocketStatusConnected ?? Colors.green;
          statusIcon = Icons.wifi;
        } else if (webSocketStore.isConnecting || webSocketStore.isReconnecting) {
          statusColor = themeExtension?.websocketStatusConnecting ?? Colors.orange;
          statusIcon = Icons.wifi_off;
        } else {
          statusColor = themeExtension?.websocketStatusDisconnected ?? Colors.red;
          statusIcon = Icons.wifi_off;
        }
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                statusIcon,
                color: statusColor,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                webSocketStore.connectionStatus,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainDisplay(BuildContext context) {
    return Consumer<DisplayStore>(
      builder: (context, displayStore, child) {
        return Stack(
          children: [
            // Main content based on display mode
            if (displayStore.isVuMeterMode)
              _buildVuMeterView(context, displayStore)
            else
              _buildKnobsView(context, displayStore),
            
            // Parameter overlay (only in VU meter mode)
            if (displayStore.showParameterOverlay && displayStore.isVuMeterMode)
              _buildParameterOverlay(context, displayStore),
          ],
        );
      },
    );
  }

  Widget _buildVuMeterView(BuildContext context, DisplayStore displayStore) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.graphic_eq,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'VU Meter',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'VU meter component will be implemented here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKnobsView(BuildContext context, DisplayStore displayStore) {
    return Consumer<ParameterStore>(
      builder: (context, parameterStore, child) {
        final parameters = parameterStore.getParametersForPage(displayStore.currentKnobPage);
        
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Column(
            children: [
              // Knobs grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: parameters.length,
                    itemBuilder: (context, index) {
                      final parameter = parameters[index];
                      return KnobCard(
                        parameter: parameter,
                        onTap: () {
                          // Handle knob tap - could show overlay or enable editing
                          displayStore.onParameterChanged(parameter);
                        },
                        onValueChanged: (value) {
                          // Handle knob value changes - go through parameter store like Vue.js
                          final parameterStore = Provider.of<ParameterStore>(context, listen: false);
                          parameterStore.updateParameter(parameter.id, value, shouldBroadcast: true);
                        },
                      );
                    },
                  ),
                ),
              ),
              
              // Page indicator
              if (displayStore.totalKnobPages > 1)
                _buildPageIndicator(context, displayStore),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKnobPlaceholder(BuildContext context, parameter) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Parameter name
          Text(
            parameter.name,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 8),
          
          // Knob placeholder
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.adjust,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Parameter value
          Text(
            parameter.text,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(BuildContext context, DisplayStore displayStore) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          displayStore.totalKnobPages,
          (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == displayStore.currentKnobPage
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParameterOverlay(BuildContext context, DisplayStore displayStore) {
    final parameter = displayStore.overlayParameter;
    if (parameter == null) return const SizedBox.shrink();
    
    final themeExtension = Theme.of(context).extension<HardwareControllerThemeExtension>();
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: themeExtension?.parameterOverlayBackground ?? 
                   Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Parameter value
              Text(
                parameter.text,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: themeExtension?.parameterOverlayText ?? 
                         Theme.of(context).colorScheme.onSurface,
                  fontFamily: 'CourierNew',
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Parameter name
              Text(
                parameter.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: themeExtension?.parameterNameText ?? 
                         Theme.of(context).colorScheme.primary,
                  fontFamily: 'CourierNew',
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 