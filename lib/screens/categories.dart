import 'package:flutter/material.dart';

import '../icons.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../ui.dart';

/// Création / modification d'une catégorie perso. Renvoie la clé de la catégorie créée.
Future<String?> editCategory(BuildContext context, [Cat? cat]) async {
  final store = StoreScope.read(context);
  final name = TextEditingController(text: cat?.name ?? '');
  var kind = cat?.kind ?? 'gift';
  var color = cat?.color ?? (customCats.length % Tk.customCatLight.length);
  final res = await showSheet<String>(context,
      title: cat == null ? 'Nouvelle catégorie' : 'Catégorie',
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
            final t = TkScope.of(ctx);
            final palette = t.dark ? Tk.customCatDark : Tk.customCatLight;
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Field('Nom', controller: name, hint: 'Ex. Animaux, Bébé, Abonnements…', autofocus: cat == null),
              const SizedBox(height: 18),
              SectionLabel('Icône'),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final k in expenseKinds)
                  Pressable(
                    onTap: () => set(() => kind = k),
                    child: Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: kind == k ? palette[color].withValues(alpha: 0.18) : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: kind == k ? palette[color] : t.line, width: kind == k ? 2 : 1),
                      ),
                      child: Ico(k, size: 22, color: kind == k ? palette[color] : t.muted),
                    ),
                  ),
              ]),
              const SizedBox(height: 18),
              SectionLabel('Couleur'),
              const SizedBox(height: 8),
              Wrap(spacing: 10, runSpacing: 10, children: [
                for (var i = 0; i < palette.length; i++)
                  Pressable(
                    onTap: () => set(() => color = i),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: palette[i],
                        shape: BoxShape.circle,
                        border: Border.all(color: color == i ? t.ink : Colors.transparent, width: 2.5),
                      ),
                    ),
                  ),
              ]),
              const SizedBox(height: 22),
              PrimaryButton('Enregistrer', onTap: () => Navigator.pop(ctx, 'save')),
              if (cat != null) ...[
                const SizedBox(height: 10),
                SecondaryButton('Supprimer la catégorie', color: t.warn, onTap: () => Navigator.pop(ctx, 'delete')),
              ],
            ]);
          }));
  if (!context.mounted) return null;
  if (res == 'delete' && cat != null) {
    if (await confirm(context, 'Supprimer « ${cat.name} » ?',
        'Ses dépenses, récurrences et son enveloppe passeront dans « Autres ».')) {
      store.deleteCategory(cat);
    }
    return null;
  }
  if (res != 'save') return null;
  final n = name.text.trim();
  if (n.isEmpty) return null;
  if (cat == null) {
    store.addCategory(n, kind, color);
    return customCats.last.key;
  }
  store.updateCategory(cat, n, kind, color);
  return cat.key;
}

/// Liste des catégories (Profil).
Future<void> manageCategories(BuildContext context) => showSheet<void>(context,
    title: 'Catégories',
    builder: (ctx) => ListenableBuilder(
          listenable: StoreScope.read(context),
          builder: (ctx, _) {
            final t = TkScope.of(ctx);
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (final c in cats)
                Ruled(
                  child: ItemRow(
                    leading: CatIcon(cat: c.key, size: 34),
                    title: c.name,
                    subtitle: c.custom ? 'Perso · touche pour modifier' : 'Catégorie de base',
                    onTap: c.custom ? () => editCategory(ctx, c) : null,
                  ),
                ),
              const SizedBox(height: 14),
              DashedButton('+ Nouvelle catégorie', onTap: () => editCategory(ctx)),
              const SizedBox(height: 6),
              Text('Les catégories de base ne peuvent pas être supprimées.',
                  textAlign: TextAlign.center, style: t.ts(12, t.wSemi, t.muted)),
            ]);
          },
        ));
