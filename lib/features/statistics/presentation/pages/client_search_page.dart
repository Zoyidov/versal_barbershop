import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../cubit/client_search_cubit.dart';
import '../widgets/client_stat_card.dart';
import 'client_detail_page.dart';

/// Full-screen search opened from the nav bar's search capsule - types a
/// phone number or client name, sees matching clients in real time, taps
/// through to their existing statistics/history page.
class ClientSearchPage extends StatelessWidget {
  const ClientSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ClientSearchCubit>(),
      child: const _ClientSearchView(),
    );
  }
}

class _ClientSearchView extends StatefulWidget {
  const _ClientSearchView();

  @override
  State<_ClientSearchView> createState() => _ClientSearchViewState();
}

class _ClientSearchViewState extends State<_ClientSearchView> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceGlass,
                          borderRadius: BorderRadius.circular(21),
                          border: Border.all(
                            color: _isFocused ? AppColors.gold : AppColors.surfaceGlassBorder,
                            width: 1.4,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                focusNode: _focusNode,
                                style: AppTextStyles.body,
                                textAlignVertical: TextAlignVertical.center,
                                decoration:  InputDecoration(
                                  hintText: 'Ism yoki telefon raqami...',
                                  hintStyle: AppTextStyles.bodyMuted,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,

                                  filled: true,
                                  fillColor: Colors.transparent,
                                ),
                                onChanged: context.read<ClientSearchCubit>().onQueryChanged,
                              ),
                            ),
                            BlocBuilder<ClientSearchCubit, ClientSearchState>(
                              buildWhen: (p, c) => p.query != c.query,
                              builder: (context, state) {
                                if (state.query.isEmpty) return const SizedBox.shrink();
                                return GestureDetector(
                                  onTap: () {
                                    _controller.clear();
                                    context.read<ClientSearchCubit>().onQueryChanged('');
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.only(left: 8),
                                    child: Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: BlocBuilder<ClientSearchCubit, ClientSearchState>(
                  builder: (context, state) {
                    if (state.status == ClientSearchStatus.idle) {
                      return Center(
                        child: Text('Mijoz qidirish uchun yozing', style: AppTextStyles.bodyMuted),
                      );
                    }
                    if (state.status == ClientSearchStatus.loading) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.gold));
                    }
                    if (state.status == ClientSearchStatus.error) {
                      return Center(
                        child: Text(state.errorMessage ?? 'Xatolik yuz berdi', style: AppTextStyles.bodyMuted),
                      );
                    }
                    if (state.results.isEmpty) {
                      return Center(
                        child: Text('Hech narsa topilmadi', style: AppTextStyles.bodyMuted),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: state.results.length,
                      itemBuilder: (context, index) {
                        final client = state.results[index];
                        return ClientStatCard(
                          stat: client,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => ClientDetailPage(client: client)),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
