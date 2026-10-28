import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Tocar una emoción abre el acompañamiento (HU-02.3, fase 2): versículo,
/// reflexión y oración, con «Más versículos de este tema» hacia el feed.
void openEmotion(BuildContext context, String slug) =>
    context.push('/acompanamiento/emocion/$slug');

/// Tocar un momento abre su acompañamiento.
void openMoment(BuildContext context, String slug) =>
    context.push('/acompanamiento/momento/$slug');

/// Abre el feed en modo tema («Tema: nombre · Salir»).
void openThemeFeed(
  BuildContext context,
  String slug, {
  bool isMoment = false,
}) => context.go(
  isMoment ? '/versiculos?momento=$slug' : '/versiculos?tema=$slug',
);
