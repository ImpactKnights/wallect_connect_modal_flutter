import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:web3modal_flutter/models/launch_url_exception.dart';
import 'package:web3modal_flutter/models/listings.dart';
import 'package:web3modal_flutter/pages/get_wallet_page.dart';
import 'package:web3modal_flutter/pages/help_page.dart';
import 'package:web3modal_flutter/services/toast/toast_message.dart';
import 'package:web3modal_flutter/services/toast/toast_service.dart';
import 'package:web3modal_flutter/utils/logger_util.dart';

import 'package:web3modal_flutter/widgets/qr_code_widget.dart';
import 'package:web3modal_flutter/services/web3modal/i_web3modal_service.dart';
import 'package:web3modal_flutter/utils/util.dart';
import 'package:web3modal_flutter/widgets/grid_list/grid_list.dart';
import 'package:web3modal_flutter/widgets/toast/web3modal_toast_manager.dart';
import 'package:web3modal_flutter/widgets/transition_container.dart';
import 'package:web3modal_flutter/widgets/web3modal_navbar.dart';
import 'package:web3modal_flutter/widgets/web3modal_navbar_title.dart';
import 'package:web3modal_flutter/widgets/web3modal_search_bar.dart';
import 'package:web3modal_flutter/widgets/web3modal_theme.dart';

class Web3Modal extends StatefulWidget {
  const Web3Modal({
    super.key,
    required this.service,
    required this.toastService,
    this.startState,
  });

  final IWeb3ModalService service;
  final ToastService toastService;
  final Web3ModalState? startState;

  @override
  State<Web3Modal> createState() => _Web3ModalState();
}

class _Web3ModalState extends State<Web3Modal>
    with SingleTickerProviderStateMixin {
  bool _initialized = false;

  // Web3Modal State
  final List<Web3ModalState> _stateStack = [];

  // Wallet List
  // final List<GridListItemModel> _wallets = [];

  // Animations
  // late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    if (widget.startState != null) {
      _stateStack.add(widget.startState!);
    } else {
      final PlatformType pType = Util.getPlatformType();

      // Choose the state based on platform
      if (pType == PlatformType.mobile) {
        _stateStack.add(Web3ModalState.walletListShort);
      } else if (pType == PlatformType.desktop) {
        _stateStack.add(Web3ModalState.qrCodeAndWalletList);
      }
    }

    initialize();
  }

  Future<void> initialize() async {
    setState(() {
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Web3ModalTheme theme = Web3ModalTheme.of(context);

    final BorderRadius containerBorderRadius = Util.isMobileWidth(context)
        ? BorderRadius.only(
            topLeft: Radius.circular(
              theme.data.radius3XS,
            ),
            topRight: Radius.circular(
              theme.data.radius3XS,
            ),
          )
        : BorderRadius.circular(
            theme.data.radius3XS,
          );

    return Container(
      // constraints: const BoxConstraints(
      //   minWidth: 200,
      //   maxWidth: 400,
      // ),
      decoration: BoxDecoration(
        color: theme.data.primary100,
        borderRadius: containerBorderRadius,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    SvgPicture.asset(
                      'assets/walletconnect_logo_white.svg',
                      width: 20,
                      height: 20,
                      package: 'web3modal_flutter',
                      colorFilter: ColorFilter.mode(
                        theme.data.foreground100,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'WalletConnect',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            color: theme.data.foreground100,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    IconButton(
                      icon: _stateStack.last == Web3ModalState.help
                          ? const Icon(Icons.help_outlined)
                          : const Icon(Icons.help_outline),
                      onPressed: () {
                        if (_stateStack.contains(Web3ModalState.help)) {
                          _popUntil(Web3ModalState.help);
                        } else {
                          setState(() {
                            _stateStack.add(Web3ModalState.help);
                          });
                        }
                      },
                      color: theme.data.foreground100,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        widget.service.close();
                      },
                      color: theme.data.foreground100,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(
                  theme.data.radius2XS,
                ),
                topRight: Radius.circular(
                  theme.data.radius2XS,
                ),
              ),
              color: theme.data.background100,
            ),
            padding: const EdgeInsets.only(
              bottom: 20,
            ),
            child: Stack(
              children: [
                TransitionContainer(
                  child: _buildBody(),
                ),
                Web3ModalToastManager(
                  toastService: widget.toastService,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (!_initialized) {
      return Container(
        constraints: const BoxConstraints(
          minWidth: 300,
          maxWidth: 400,
          minHeight: 300,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircularProgressIndicator(
              color: Web3ModalTheme.of(context).data.primary100,
            ),
          ),
        ),
      );
    }

    switch (_stateStack.last) {
      case Web3ModalState.qrCode:
        return Web3ModalNavBar(
          key: Key(Web3ModalState.qrCode.name),
          title: const Web3ModalNavbarTitle(
            title: 'Scan QR Code',
          ),
          onBack: _pop,
          actionWidget: IconButton(
            icon: const Icon(Icons.copy_outlined),
            color: Web3ModalTheme.of(context).data.foreground100,
            onPressed: _copyQrCodeToClipboard,
          ),
          child: QRCodePage(
            qrData: widget.service.wcUri!,
            logoPath: 'assets/walletconnect_logo_white.png',
          ),
        );
      case Web3ModalState.walletListShort:
        return Web3ModalNavBar(
          key: Key(Web3ModalState.walletListShort.name),
          title: const Web3ModalNavbarTitle(
            title: 'Connect your wallet',
          ),
          actionWidget: IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            color: Web3ModalTheme.of(context).data.foreground100,
            onPressed: _toQrCode,
          ),
          child: GridList<WalletData>(
            state: GridListState.short,
            provider: widget.service.explorerService,
            viewLongList: _viewLongWalletList,
            onSelect: _onWalletDataSelected,
          ),
        );
      case Web3ModalState.walletListLong:
        return Web3ModalNavBar(
          key: Key(Web3ModalState.walletListLong.name),
          title: Web3ModalSearchBar(
            hintText: 'Search ${Util.getPlatformType().name} wallets',
            onSearch: _updateSearch,
          ),
          onBack: _pop,
          child: GridList<WalletData>(
            // key: ValueKey('${GridListState.long}$_searchQuery'),
            state: GridListState.long,
            provider: widget.service.explorerService,
            viewLongList: _viewLongWalletList,
            onSelect: _onWalletDataSelected,
          ),
        );
      case Web3ModalState.qrCodeAndWalletList:
        return Web3ModalNavBar(
          key: Key(
            Web3ModalState.qrCodeAndWalletList.name,
          ),
          title: const Web3ModalNavbarTitle(
            title: 'Connect your wallet',
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              QRCodePage(
                qrData: widget.service.wcUri!,
                logoPath: 'assets/walletconnect_logo_white.png',
              ),
              GridList(
                state: GridListState.extraShort,
                provider: widget.service.explorerService,
                viewLongList: _viewLongWalletList,
                onSelect: _onWalletDataSelected,
              ),
            ],
          ),
        );
      case Web3ModalState.chainList:
        return Web3ModalNavBar(
          // TODO: Update this to display chains, not wallets
          key: Key(Web3ModalState.chainList.name),
          title: const Web3ModalNavbarTitle(
            title: 'Select network',
          ),
          child: GridList(
            state: GridListState.extraShort,
            provider: widget.service.explorerService,
            viewLongList: _viewLongWalletList,
            onSelect: _onWalletDataSelected,
          ),
        );
      case Web3ModalState.help:
        return Web3ModalNavBar(
          key: Key(Web3ModalState.help.name),
          title: const Web3ModalNavbarTitle(
            title: 'Help',
          ),
          onBack: _pop,
          child: HelpPage(
            getAWallet: () {
              setState(() {
                _stateStack.add(Web3ModalState.getAWallet);
              });
            },
          ),
        );
      case Web3ModalState.getAWallet:
        return Web3ModalNavBar(
          key: Key(Web3ModalState.getAWallet.name),
          title: const Web3ModalNavbarTitle(
            title: 'Get a wallet',
          ),
          onBack: _pop,
          child: GetWalletPage(
            service: widget.service.explorerService,
          ),
        );
      default:
        return Container();
    }
  }

  Future<void> _onWalletDataSelected(WalletData item) async {
    LoggerUtil.logger.v(
      'Selected ${item.listing.name}. Installed: ${item.installed} Item info: $item.',
    );
    try {
      await Util.navigateDeepLink(
        nativeLink: item.listing.mobile.native,
        universalLink: item.listing.mobile.universal,
        wcURI: widget.service.wcUri!,
      );
    } on LaunchUrlException catch (e) {
      widget.toastService.show(
        ToastMessage(
          type: ToastType.error,
          text: e.message,
        ),
      );
    }
  }

  void _viewLongWalletList() {
    setState(() {
      _stateStack.add(Web3ModalState.walletListLong);
    });
  }

  void _pop() {
    setState(() {
      // Remove all of the elements until we get to the help state
      final state = _stateStack.removeLast();

      if (state == Web3ModalState.walletListLong) {
        widget.service.explorerService.filterList(query: '');
      }
    });
  }

  void _popUntil(Web3ModalState targetState) {
    setState(() {
      // Remove all of the elements until we get to the help state
      Web3ModalState removedState = _stateStack.removeLast();
      while (removedState != Web3ModalState.help) {
        removedState = _stateStack.removeLast();

        if (removedState == Web3ModalState.walletListLong) {
          widget.service.explorerService.filterList(query: '');
        }
      }
    });
  }

  void _toQrCode() {
    setState(() {
      _stateStack.add(Web3ModalState.qrCode);
    });
  }

  Future<void> _copyQrCodeToClipboard() async {
    await Clipboard.setData(
      ClipboardData(
        text: widget.service.wcUri!,
      ),
    );
    widget.toastService.show(
      ToastMessage(
        type: ToastType.info,
        text: 'QR Copied',
      ),
    );
  }

  void _updateSearch(String query) {
    widget.service.explorerService.filterList(query: query);
  }
}
