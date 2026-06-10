import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/view_state.dart';
import '../providers/auth_provider.dart';
import '../providers/venues_provider.dart';
import '../widgets/venue_card.dart';
import 'slots_screen.dart';

class VenuesScreen extends StatefulWidget {
  const VenuesScreen({super.key});

  @override
  State<VenuesScreen> createState() => _VenuesScreenState();
}

class _VenuesScreenState extends State<VenuesScreen> {
  @override
  void initState() {
    super.initState();
    // addPostFrameCallback so the provider call happens after the first build,
    // avoiding notifyListeners-during-build errors.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VenuesProvider>().loadVenues();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VenuesProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('QuickSlot'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: switch (provider.state) {
        ViewState.idle || ViewState.loading => const Center(
            child: CircularProgressIndicator(),
          ),
        ViewState.error => _ErrorView(
            message: provider.errorMessage ?? 'Something went wrong',
            onRetry: () => context.read<VenuesProvider>().loadVenues(),
          ),
        ViewState.success => provider.venues.isEmpty
            ? const _EmptyView()
            : RefreshIndicator(
                onRefresh: () => context.read<VenuesProvider>().loadVenues(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.venues.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final venue = provider.venues[i];
                    return VenueCard(
                      venue: venue,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SlotsScreen(venue: venue),
                        ),
                      ),
                    );
                  },
                ),
              ),
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 56, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stadium_outlined,
              size: 56, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text('No venues yet',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  )),
        ],
      ),
    );
  }
}
