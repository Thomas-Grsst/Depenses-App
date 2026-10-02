# Dépenses

App Android de suivi des dépenses personnelles, en Flutter. Les données restent sur le téléphone.

- Solde du compte tenu à jour (dépenses, salaire au jour de paie) et estimation de fin de mois
- Dépenses occasionnelles et récurrentes (calendrier des échéances)
- Budget par catégorie et enveloppes par libellé, alertes de rythme
- Catégories personnalisées
- Prévision du mois, comparaison avec le mois précédent
- Simulations (« et si mon loyer passait à 900 € ? ») sans toucher au budget
- Deux styles : Menthe (palettes Menthe, Océan, Prune, Terracotta) et Graphite, en clair ou sombre

## Compiler l'APK

```bash
flutter pub get
flutter build apk --release
```

L'APK est généré dans `build/app/outputs/flutter-apk/app-release.apk`.
