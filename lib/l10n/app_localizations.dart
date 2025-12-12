import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'MarketMove'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In es, this message translates to:
  /// **'Iniciar Sesión'**
  String get login;

  /// No description provided for @register.
  ///
  /// In es, this message translates to:
  /// **'Registrarse'**
  String get register;

  /// No description provided for @email.
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get password;

  /// No description provided for @enter.
  ///
  /// In es, this message translates to:
  /// **'Entrar'**
  String get enter;

  /// No description provided for @createAccount.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get createAccount;

  /// No description provided for @back.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get back;

  /// No description provided for @logout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar Sesión'**
  String get logout;

  /// No description provided for @forgotPassword.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get forgotPassword;

  /// No description provided for @recoverPassword.
  ///
  /// In es, this message translates to:
  /// **'Recuperar Contraseña'**
  String get recoverPassword;

  /// No description provided for @sendEmail.
  ///
  /// In es, this message translates to:
  /// **'Enviar correo'**
  String get sendEmail;

  /// No description provided for @home.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get home;

  /// No description provided for @products.
  ///
  /// In es, this message translates to:
  /// **'Productos'**
  String get products;

  /// No description provided for @sales.
  ///
  /// In es, this message translates to:
  /// **'Ventas'**
  String get sales;

  /// No description provided for @expenses.
  ///
  /// In es, this message translates to:
  /// **'Gastos'**
  String get expenses;

  /// No description provided for @statistics.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas'**
  String get statistics;

  /// No description provided for @profile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get profile;

  /// No description provided for @newProduct.
  ///
  /// In es, this message translates to:
  /// **'Nuevo Producto'**
  String get newProduct;

  /// No description provided for @editProduct.
  ///
  /// In es, this message translates to:
  /// **'Editar Producto'**
  String get editProduct;

  /// No description provided for @productDetail.
  ///
  /// In es, this message translates to:
  /// **'Detalle de Producto'**
  String get productDetail;

  /// No description provided for @newSale.
  ///
  /// In es, this message translates to:
  /// **'Nueva Venta'**
  String get newSale;

  /// No description provided for @editSale.
  ///
  /// In es, this message translates to:
  /// **'Editar Venta'**
  String get editSale;

  /// No description provided for @saleDetail.
  ///
  /// In es, this message translates to:
  /// **'Detalle de Venta'**
  String get saleDetail;

  /// No description provided for @newExpense.
  ///
  /// In es, this message translates to:
  /// **'Nuevo Gasto'**
  String get newExpense;

  /// No description provided for @editExpense.
  ///
  /// In es, this message translates to:
  /// **'Editar Gasto'**
  String get editExpense;

  /// No description provided for @expenseDetail.
  ///
  /// In es, this message translates to:
  /// **'Detalle de Gasto'**
  String get expenseDetail;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In es, this message translates to:
  /// **'Añadir'**
  String get add;

  /// No description provided for @search.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get search;

  /// No description provided for @noData.
  ///
  /// In es, this message translates to:
  /// **'No hay datos'**
  String get noData;

  /// No description provided for @loading.
  ///
  /// In es, this message translates to:
  /// **'Cargando...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In es, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In es, this message translates to:
  /// **'Éxito'**
  String get success;

  /// No description provided for @invalidCredentials.
  ///
  /// In es, this message translates to:
  /// **'Credenciales incorrectas'**
  String get invalidCredentials;

  /// No description provided for @emailAlreadyExists.
  ///
  /// In es, this message translates to:
  /// **'El email ya está registrado'**
  String get emailAlreadyExists;

  /// No description provided for @registrationSuccess.
  ///
  /// In es, this message translates to:
  /// **'Registro exitoso'**
  String get registrationSuccess;

  /// No description provided for @loginSuccess.
  ///
  /// In es, this message translates to:
  /// **'Inicio de sesión exitoso'**
  String get loginSuccess;

  /// No description provided for @logoutSuccess.
  ///
  /// In es, this message translates to:
  /// **'Sesión cerrada'**
  String get logoutSuccess;

  /// No description provided for @homeSummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen de ventas, gastos y stock'**
  String get homeSummary;

  /// No description provided for @preferEnglish.
  ///
  /// In es, this message translates to:
  /// **'Prefer English? Click here!'**
  String get preferEnglish;

  /// No description provided for @preferSpanish.
  ///
  /// In es, this message translates to:
  /// **'¿Prefieres español? ¡Haz clic aquí!'**
  String get preferSpanish;

  /// No description provided for @salesSummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen de Ventas'**
  String get salesSummary;

  /// No description provided for @expensesSummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen de Gastos'**
  String get expensesSummary;

  /// No description provided for @stockSummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen de Stock'**
  String get stockSummary;

  /// No description provided for @totalSales.
  ///
  /// In es, this message translates to:
  /// **'Total Ventas'**
  String get totalSales;

  /// No description provided for @totalExpenses.
  ///
  /// In es, this message translates to:
  /// **'Total Gastos'**
  String get totalExpenses;

  /// No description provided for @totalProducts.
  ///
  /// In es, this message translates to:
  /// **'Total Productos'**
  String get totalProducts;

  /// No description provided for @name.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get name;

  /// No description provided for @price.
  ///
  /// In es, this message translates to:
  /// **'Precio'**
  String get price;

  /// No description provided for @category.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get category;

  /// No description provided for @barcode.
  ///
  /// In es, this message translates to:
  /// **'Código de Barras'**
  String get barcode;

  /// No description provided for @requiredField.
  ///
  /// In es, this message translates to:
  /// **'Campo obligatorio'**
  String get requiredField;

  /// No description provided for @invalidValue.
  ///
  /// In es, this message translates to:
  /// **'Valor inválido'**
  String get invalidValue;

  /// No description provided for @confirmDelete.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas eliminar este elemento?'**
  String get confirmDelete;

  /// No description provided for @amount.
  ///
  /// In es, this message translates to:
  /// **'Importe'**
  String get amount;

  /// No description provided for @quantity.
  ///
  /// In es, this message translates to:
  /// **'Cantidad'**
  String get quantity;

  /// No description provided for @date.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get date;

  /// No description provided for @paymentMethod.
  ///
  /// In es, this message translates to:
  /// **'Método de Pago'**
  String get paymentMethod;

  /// No description provided for @comments.
  ///
  /// In es, this message translates to:
  /// **'Comentarios'**
  String get comments;

  /// No description provided for @product.
  ///
  /// In es, this message translates to:
  /// **'Producto'**
  String get product;

  /// No description provided for @profit.
  ///
  /// In es, this message translates to:
  /// **'Beneficio'**
  String get profit;

  /// No description provided for @stock.
  ///
  /// In es, this message translates to:
  /// **'Stock'**
  String get stock;

  /// No description provided for @welcome.
  ///
  /// In es, this message translates to:
  /// **'¡Bienvenido!'**
  String get welcome;

  /// No description provided for @manageInventory.
  ///
  /// In es, this message translates to:
  /// **'Gestiona tu inventario'**
  String get manageInventory;

  /// No description provided for @registerSales.
  ///
  /// In es, this message translates to:
  /// **'Registra tus ventas'**
  String get registerSales;

  /// No description provided for @controlExpenses.
  ///
  /// In es, this message translates to:
  /// **'Controla tus gastos'**
  String get controlExpenses;

  /// No description provided for @analyzeYourBusiness.
  ///
  /// In es, this message translates to:
  /// **'Analiza tu negocio'**
  String get analyzeYourBusiness;

  /// No description provided for @yourAccount.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta'**
  String get yourAccount;

  /// No description provided for @invalidId.
  ///
  /// In es, this message translates to:
  /// **'ID inválido'**
  String get invalidId;

  /// No description provided for @accountInfo.
  ///
  /// In es, this message translates to:
  /// **'Información de la cuenta'**
  String get accountInfo;

  /// No description provided for @role.
  ///
  /// In es, this message translates to:
  /// **'Rol'**
  String get role;

  /// No description provided for @language.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get language;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @accept.
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get accept;

  /// No description provided for @noProducts.
  ///
  /// In es, this message translates to:
  /// **'No hay productos'**
  String get noProducts;

  /// No description provided for @noSales.
  ///
  /// In es, this message translates to:
  /// **'No hay ventas'**
  String get noSales;

  /// No description provided for @noExpenses.
  ///
  /// In es, this message translates to:
  /// **'No hay gastos'**
  String get noExpenses;

  /// No description provided for @loadError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar'**
  String get loadError;

  /// No description provided for @unexpectedError.
  ///
  /// In es, this message translates to:
  /// **'Error inesperado'**
  String get unexpectedError;

  /// No description provided for @paymentCash.
  ///
  /// In es, this message translates to:
  /// **'Efectivo'**
  String get paymentCash;

  /// No description provided for @paymentCard.
  ///
  /// In es, this message translates to:
  /// **'Tarjeta'**
  String get paymentCard;

  /// No description provided for @paymentTransfer.
  ///
  /// In es, this message translates to:
  /// **'Transferencia'**
  String get paymentTransfer;

  /// No description provided for @paymentBizum.
  ///
  /// In es, this message translates to:
  /// **'Bizum'**
  String get paymentBizum;

  /// No description provided for @paymentOther.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get paymentOther;

  /// No description provided for @categoryRent.
  ///
  /// In es, this message translates to:
  /// **'Alquiler'**
  String get categoryRent;

  /// No description provided for @categoryServices.
  ///
  /// In es, this message translates to:
  /// **'Servicios'**
  String get categoryServices;

  /// No description provided for @categorySupplies.
  ///
  /// In es, this message translates to:
  /// **'Suministros'**
  String get categorySupplies;

  /// No description provided for @categoryTransport.
  ///
  /// In es, this message translates to:
  /// **'Transporte'**
  String get categoryTransport;

  /// No description provided for @categoryMarketing.
  ///
  /// In es, this message translates to:
  /// **'Marketing'**
  String get categoryMarketing;

  /// No description provided for @categoryAdvertising.
  ///
  /// In es, this message translates to:
  /// **'Publicidad'**
  String get categoryAdvertising;

  /// No description provided for @categoryMaterial.
  ///
  /// In es, this message translates to:
  /// **'Material'**
  String get categoryMaterial;

  /// No description provided for @categoryShipping.
  ///
  /// In es, this message translates to:
  /// **'Envíos'**
  String get categoryShipping;

  /// No description provided for @categoryClothing.
  ///
  /// In es, this message translates to:
  /// **'Ropa'**
  String get categoryClothing;

  /// No description provided for @categoryAccessories.
  ///
  /// In es, this message translates to:
  /// **'Accesorios'**
  String get categoryAccessories;

  /// No description provided for @categoryOther.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get categoryOther;

  /// No description provided for @deleteProductConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas eliminar este producto?'**
  String get deleteProductConfirm;

  /// No description provided for @deleteSaleConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas eliminar esta venta?'**
  String get deleteSaleConfirm;

  /// No description provided for @deleteExpenseConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas eliminar este gasto?'**
  String get deleteExpenseConfirm;

  /// No description provided for @deleteUserConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas eliminar este usuario?'**
  String get deleteUserConfirm;

  /// No description provided for @deleteUserWarning.
  ///
  /// In es, this message translates to:
  /// **'Esto también eliminará todos sus productos, ventas y gastos.'**
  String get deleteUserWarning;

  /// No description provided for @productSaved.
  ///
  /// In es, this message translates to:
  /// **'Producto guardado'**
  String get productSaved;

  /// No description provided for @saleSaved.
  ///
  /// In es, this message translates to:
  /// **'Venta guardada'**
  String get saleSaved;

  /// No description provided for @expenseSaved.
  ///
  /// In es, this message translates to:
  /// **'Gasto guardado'**
  String get expenseSaved;

  /// No description provided for @productDeleted.
  ///
  /// In es, this message translates to:
  /// **'Producto eliminado'**
  String get productDeleted;

  /// No description provided for @saleDeleted.
  ///
  /// In es, this message translates to:
  /// **'Venta eliminada'**
  String get saleDeleted;

  /// No description provided for @expenseDeleted.
  ///
  /// In es, this message translates to:
  /// **'Gasto eliminado'**
  String get expenseDeleted;

  /// No description provided for @roleUser.
  ///
  /// In es, this message translates to:
  /// **'Usuario'**
  String get roleUser;

  /// No description provided for @roleAdmin.
  ///
  /// In es, this message translates to:
  /// **'Administrador'**
  String get roleAdmin;

  /// No description provided for @roleSuperAdmin.
  ///
  /// In es, this message translates to:
  /// **'Super Admin'**
  String get roleSuperAdmin;

  /// No description provided for @adminPanel.
  ///
  /// In es, this message translates to:
  /// **'Panel de Administración'**
  String get adminPanel;

  /// No description provided for @usersManagement.
  ///
  /// In es, this message translates to:
  /// **'Gestión de usuarios'**
  String get usersManagement;

  /// No description provided for @totalUsers.
  ///
  /// In es, this message translates to:
  /// **'Total Usuarios'**
  String get totalUsers;

  /// No description provided for @admins.
  ///
  /// In es, this message translates to:
  /// **'Administradores'**
  String get admins;

  /// No description provided for @users.
  ///
  /// In es, this message translates to:
  /// **'Usuarios'**
  String get users;

  /// No description provided for @changeRole.
  ///
  /// In es, this message translates to:
  /// **'Cambiar rol'**
  String get changeRole;

  /// No description provided for @selectNewRole.
  ///
  /// In es, this message translates to:
  /// **'Selecciona el nuevo rol para'**
  String get selectNewRole;

  /// No description provided for @roleUpdated.
  ///
  /// In es, this message translates to:
  /// **'Rol actualizado correctamente'**
  String get roleUpdated;

  /// No description provided for @roleUpdateFailed.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar el rol'**
  String get roleUpdateFailed;

  /// No description provided for @userDeleted.
  ///
  /// In es, this message translates to:
  /// **'Usuario eliminado correctamente'**
  String get userDeleted;

  /// No description provided for @userDeleteFailed.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar el usuario'**
  String get userDeleteFailed;

  /// No description provided for @you.
  ///
  /// In es, this message translates to:
  /// **'Tú'**
  String get you;

  /// No description provided for @superAdminMode.
  ///
  /// In es, this message translates to:
  /// **'Modo Super Admin'**
  String get superAdminMode;

  /// No description provided for @viewAllData.
  ///
  /// In es, this message translates to:
  /// **'Ver todos los datos'**
  String get viewAllData;

  /// No description provided for @viewOnlyMine.
  ///
  /// In es, this message translates to:
  /// **'Ver solo mis datos'**
  String get viewOnlyMine;

  /// No description provided for @globalProducts.
  ///
  /// In es, this message translates to:
  /// **'Productos Globales'**
  String get globalProducts;

  /// No description provided for @globalSales.
  ///
  /// In es, this message translates to:
  /// **'Ventas Globales'**
  String get globalSales;

  /// No description provided for @globalExpenses.
  ///
  /// In es, this message translates to:
  /// **'Gastos Globales'**
  String get globalExpenses;

  /// No description provided for @globalStatistics.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas Globales'**
  String get globalStatistics;

  /// No description provided for @viewAllProducts.
  ///
  /// In es, this message translates to:
  /// **'Ver todos los productos'**
  String get viewAllProducts;

  /// No description provided for @viewAllSales.
  ///
  /// In es, this message translates to:
  /// **'Ver todas las ventas'**
  String get viewAllSales;

  /// No description provided for @viewAllExpenses.
  ///
  /// In es, this message translates to:
  /// **'Ver todos los gastos'**
  String get viewAllExpenses;

  /// No description provided for @systemAnalysis.
  ///
  /// In es, this message translates to:
  /// **'Análisis de todo el sistema'**
  String get systemAnalysis;

  /// No description provided for @systemManagement.
  ///
  /// In es, this message translates to:
  /// **'Gestión general del sistema'**
  String get systemManagement;

  /// No description provided for @passwordRecoveryNotAvailable.
  ///
  /// In es, this message translates to:
  /// **'La recuperación de contraseña no está disponible con autenticación personalizada'**
  String get passwordRecoveryNotAvailable;

  /// No description provided for @orLoginWith.
  ///
  /// In es, this message translates to:
  /// **'O inicia sesión con'**
  String get orLoginWith;

  /// No description provided for @dontHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta?'**
  String get alreadyHaveAccount;

  /// No description provided for @signUp.
  ///
  /// In es, this message translates to:
  /// **'Registrarse'**
  String get signUp;

  /// No description provided for @signIn.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get signIn;

  /// No description provided for @dashboard.
  ///
  /// In es, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @monthlySales.
  ///
  /// In es, this message translates to:
  /// **'Ventas Mensuales'**
  String get monthlySales;

  /// No description provided for @monthlyExpenses.
  ///
  /// In es, this message translates to:
  /// **'Gastos Mensuales'**
  String get monthlyExpenses;

  /// No description provided for @monthlyProfit.
  ///
  /// In es, this message translates to:
  /// **'Beneficio Mensual'**
  String get monthlyProfit;

  /// No description provided for @topProducts.
  ///
  /// In es, this message translates to:
  /// **'Productos Más Vendidos'**
  String get topProducts;

  /// No description provided for @paymentMethods.
  ///
  /// In es, this message translates to:
  /// **'Métodos de Pago'**
  String get paymentMethods;

  /// No description provided for @stockEvolution.
  ///
  /// In es, this message translates to:
  /// **'Evolución del Stock'**
  String get stockEvolution;

  /// No description provided for @totalProfit.
  ///
  /// In es, this message translates to:
  /// **'Beneficio Total'**
  String get totalProfit;

  /// No description provided for @totalTransactions.
  ///
  /// In es, this message translates to:
  /// **'Total Transacciones'**
  String get totalTransactions;

  /// No description provided for @salesTrend.
  ///
  /// In es, this message translates to:
  /// **'Tendencia de Ventas'**
  String get salesTrend;

  /// No description provided for @expensesTrend.
  ///
  /// In es, this message translates to:
  /// **'Tendencia de Gastos'**
  String get expensesTrend;

  /// No description provided for @profitTrend.
  ///
  /// In es, this message translates to:
  /// **'Tendencia de Beneficio'**
  String get profitTrend;

  /// No description provided for @noChartData.
  ///
  /// In es, this message translates to:
  /// **'Sin datos para mostrar'**
  String get noChartData;

  /// No description provided for @units.
  ///
  /// In es, this message translates to:
  /// **'unidades'**
  String get units;

  /// No description provided for @avgStock.
  ///
  /// In es, this message translates to:
  /// **'Stock Promedio'**
  String get avgStock;

  /// No description provided for @salesByProduct.
  ///
  /// In es, this message translates to:
  /// **'Ventas por Producto'**
  String get salesByProduct;

  /// No description provided for @last6Months.
  ///
  /// In es, this message translates to:
  /// **'Últimos 6 meses'**
  String get last6Months;

  /// No description provided for @paymentDistribution.
  ///
  /// In es, this message translates to:
  /// **'Distribución de Pagos'**
  String get paymentDistribution;

  /// No description provided for @export.
  ///
  /// In es, this message translates to:
  /// **'Exportar'**
  String get export;

  /// No description provided for @exportPdf.
  ///
  /// In es, this message translates to:
  /// **'Exportar PDF'**
  String get exportPdf;

  /// No description provided for @exportExcel.
  ///
  /// In es, this message translates to:
  /// **'Exportar Excel'**
  String get exportExcel;

  /// No description provided for @fullReport.
  ///
  /// In es, this message translates to:
  /// **'Informe Completo'**
  String get fullReport;

  /// No description provided for @reportGenerated.
  ///
  /// In es, this message translates to:
  /// **'Informe generado'**
  String get reportGenerated;

  /// No description provided for @exporting.
  ///
  /// In es, this message translates to:
  /// **'Exportando...'**
  String get exporting;

  /// No description provided for @exportSuccess.
  ///
  /// In es, this message translates to:
  /// **'Exportación exitosa'**
  String get exportSuccess;

  /// No description provided for @exportFailed.
  ///
  /// In es, this message translates to:
  /// **'Error al exportar'**
  String get exportFailed;

  /// No description provided for @chooseFormat.
  ///
  /// In es, this message translates to:
  /// **'¿Qué formato deseas exportar?'**
  String get chooseFormat;

  /// No description provided for @pdfGenerated.
  ///
  /// In es, this message translates to:
  /// **'PDF generado correctamente'**
  String get pdfGenerated;

  /// No description provided for @excelGenerated.
  ///
  /// In es, this message translates to:
  /// **'Excel generado correctamente'**
  String get excelGenerated;

  /// No description provided for @generatedBy.
  ///
  /// In es, this message translates to:
  /// **'Documento generado automáticamente por MarketMove'**
  String get generatedBy;

  /// No description provided for @summaryReport.
  ///
  /// In es, this message translates to:
  /// **'Resumen del Informe'**
  String get summaryReport;

  /// No description provided for @exportProducts.
  ///
  /// In es, this message translates to:
  /// **'Exportar Productos'**
  String get exportProducts;

  /// No description provided for @exportSales.
  ///
  /// In es, this message translates to:
  /// **'Exportar Ventas'**
  String get exportSales;

  /// No description provided for @exportExpenses.
  ///
  /// In es, this message translates to:
  /// **'Exportar Gastos'**
  String get exportExpenses;

  /// No description provided for @exportFullReport.
  ///
  /// In es, this message translates to:
  /// **'Exportar Informe Completo'**
  String get exportFullReport;

  /// No description provided for @page.
  ///
  /// In es, this message translates to:
  /// **'Página'**
  String get page;

  /// No description provided for @addImage.
  ///
  /// In es, this message translates to:
  /// **'Añadir imagen'**
  String get addImage;

  /// No description provided for @changeImage.
  ///
  /// In es, this message translates to:
  /// **'Cambiar imagen'**
  String get changeImage;

  /// No description provided for @deleteImage.
  ///
  /// In es, this message translates to:
  /// **'Eliminar imagen'**
  String get deleteImage;

  /// No description provided for @productImage.
  ///
  /// In es, this message translates to:
  /// **'Imagen del producto'**
  String get productImage;

  /// No description provided for @expenseImage.
  ///
  /// In es, this message translates to:
  /// **'Imagen del gasto'**
  String get expenseImage;

  /// No description provided for @noImage.
  ///
  /// In es, this message translates to:
  /// **'Sin imagen'**
  String get noImage;

  /// No description provided for @imageUploading.
  ///
  /// In es, this message translates to:
  /// **'Subiendo imagen...'**
  String get imageUploading;

  /// No description provided for @imageUploaded.
  ///
  /// In es, this message translates to:
  /// **'Imagen subida correctamente'**
  String get imageUploaded;

  /// No description provided for @imageDeleted.
  ///
  /// In es, this message translates to:
  /// **'Imagen eliminada'**
  String get imageDeleted;

  /// No description provided for @imageError.
  ///
  /// In es, this message translates to:
  /// **'Error con la imagen'**
  String get imageError;

  /// No description provided for @selectImage.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar imagen'**
  String get selectImage;

  /// No description provided for @viewImage.
  ///
  /// In es, this message translates to:
  /// **'Ver imagen'**
  String get viewImage;

  /// No description provided for @selectOption.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar opción'**
  String get selectOption;

  /// No description provided for @itemNotFound.
  ///
  /// In es, this message translates to:
  /// **'Elemento no encontrado'**
  String get itemNotFound;

  /// No description provided for @darkMode.
  ///
  /// In es, this message translates to:
  /// **'Modo oscuro'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In es, this message translates to:
  /// **'Modo claro'**
  String get lightMode;

  /// No description provided for @theme.
  ///
  /// In es, this message translates to:
  /// **'Tema'**
  String get theme;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
