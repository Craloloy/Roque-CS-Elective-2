import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../state/platform_settings.dart';

class AdaptiveScaffold extends StatelessWidget {
  final Widget title;
  final Widget body;
  final Widget? drawer;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final bool showDrawerButton;

  const AdaptiveScaffold({
    super.key,
    required this.title,
    required this.body,
    this.drawer,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.showDrawerButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final isCupertino = PlatformSettings.of(context).isCupertinoActive(context);
    final isDark = PlatformSettings.of(context).isDarkMode;

    if (isCupertino) {
      return CupertinoPageScaffold(
        backgroundColor: backgroundColor ??
            (isDark
                ? CupertinoColors.systemBackground.darkColor
                : const Color(0xFFF8FAFC)),
        navigationBar: CupertinoNavigationBar(
          middle: title,
          leading: (showDrawerButton && drawer != null)
              ? Builder(
                  builder: (ctx) => CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      showCupertinoModalPopup(
                        context: context,
                        builder: (_) => Container(
                          height: MediaQuery.of(context).size.height * 0.7,
                          color: isDark
                              ? CupertinoColors.darkBackgroundGray
                              : CupertinoColors.systemBackground,
                          child: SafeArea(
                            top: false,
                            child: Material(
                              type: MaterialType.transparency,
                              child: drawer!,
                            ),
                          ),
                        ),
                      );
                    },
                    child: const Icon(CupertinoIcons.bars, size: 24),
                  ),
                )
              : null,
          trailing: actions != null && actions!.isNotEmpty
              ? Material(
                  type: MaterialType.transparency,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions!,
                  ),
                )
              : null,
        ),
        child: Column(
          children: [
            Expanded(
              child: SafeArea(
                bottom: bottomNavigationBar == null,
                child: Material(
                  type: MaterialType.transparency,
                  child: body,
                ),
              ),
            ),
            ?bottomNavigationBar,
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor ??
          (isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC)),
      appBar: AppBar(
        title: title,
        centerTitle: false,
        elevation: 0.5,
        actions: actions,
      ),
      drawer: drawer,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
