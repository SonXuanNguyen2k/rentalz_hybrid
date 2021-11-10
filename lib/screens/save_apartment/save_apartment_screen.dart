import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:rentalz/alert_service.dart';
import 'package:rentalz/models/apartment/apartment_model.dart';
import 'package:rentalz/navigation_service.dart';
import 'package:rentalz/repo/apartment_repo.dart';
import 'package:rentalz/screens/save_apartment/input_location_address_screen.dart';
import 'package:rentalz/utils/data_validator.dart';
import 'package:rentalz/widgets/clearable_text_form_field.dart';
import 'package:rentalz/widgets/cupertino_picker_form_field.dart';
import 'package:rentalz/widgets/form_validation_manager.dart';
import 'package:rentalz/widgets/input_formatters/numeric_text_input_formatter.dart';

class SaveApartmentScreen extends StatelessWidget {
  const SaveApartmentScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Apartment info')),
        body: const SafeArea(child: _Body()),
      ),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({Key? key}) : super(key: key);

  @override
  _BodyState createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _formKey = GlobalKey<FormState>();
  final _formValidationManager = FormValidationManager();

  String? _name;
  String? _reporterName;
  LocationAddress? _locationAddress;
  ApartmentType? _apartmentType;
  ComfortLevel? _comfortLevel;
  String? _monthlyRent;
  String? _nBedrooms;
  String? _note;

  ClearableTextFormField get _nameFormField {
    return ClearableTextFormField(
      validator: _formValidationManager.wrapValidator(
        '_nameFormField',
        (value) =>
            DataValidator.lengthRequired(value, minLength: 3, maxLength: 40),
      ),
      onSaved: (value) => _name = value,
      focusNode: _formValidationManager.getFocusNodeForField('_nameFormField'),
      decoration: _inputDecoration.copyWith(
        prefixIcon: const Icon(Icons.info_outlined),
        labelText: "Apartment name",
      ),
    );
  }

  ClearableTextFormField get _reporterNameFormField {
    return ClearableTextFormField(
      validator: _formValidationManager.wrapValidator(
        '_reporterNameFormField',
        (value) => DataValidator.fullnameValid(value),
      ),
      onSaved: (value) => _reporterName = value,
      focusNode:
          _formValidationManager.getFocusNodeForField('_reporterNameFormField'),
      decoration: _inputDecoration.copyWith(
        prefixIcon: const Icon(Icons.person_outline),
        labelText: "Reporter's name",
      ),
    );
  }

  FormField<LocationAddress> get _locationAddressFormField {
    return FormField<LocationAddress>(
      validator: _formValidationManager.wrapValidator(
        '_locationAddressFormField',
        (value) => DataValidator.required(value),
      ),
      onSaved: (value) => _locationAddress = value,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (fieldState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MaterialButton(
            padding: const EdgeInsets.all(0),
            onPressed: () async {
              FocusManager.instance.primaryFocus?.unfocus();

              final location = await NavigationService.pushNewPage(
                      InputLocationAddressScreen(initialData: fieldState.value))
                  as LocationAddress?;
              if (location != null) {
                fieldState.didChange(location);
              }
            },
            child: AbsorbPointer(
              child: Theme(
                data: fieldState.hasError
                    ? ThemeData().copyWith(
                        colorScheme: ThemeData()
                            .colorScheme
                            .copyWith(primary: const Color(0xffd32f2f)),
                        inputDecorationTheme: const InputDecorationTheme(
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xffd32f2f)),
                          ),
                        ),
                      )
                    : Theme.of(fieldState.context),
                child: TextField(
                  keyboardType: TextInputType.streetAddress,
                  focusNode: _formValidationManager
                      .getFocusNodeForField('_locationAddressFormField'),
                  readOnly: true,
                  showCursor: false,
                  decoration: InputDecoration(
                    filled: true,
                    prefixIcon: const Icon(Icons.map_outlined),
                    floatingLabelBehavior: (fieldState.value != null)
                        ? FloatingLabelBehavior.always
                        : null,
                    labelText: "Location address",
                    suffixIcon: const Icon(Icons.chevron_right),
                    hintText: (fieldState.value != null)
                        ? fieldState.value!.formattedAddress
                        : null,
                    hintStyle: const TextStyle(color: Color(0xdd000000)),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 8),
            child: Text(
              fieldState.errorText ?? '',
              style: Theme.of(context)
                  .textTheme
                  .caption!
                  .copyWith(color: Theme.of(context).errorColor),
            ),
          ),
        ],
      ),
    );
  }

  FormField<ApartmentType> get _apartmentTypeFormField {
    return CupertinoPickerFormField<ApartmentType>(
      validator: _formValidationManager.wrapValidator(
        '_apartmentTypeFormField',
        (value) => DataValidator.required(value),
      ),
      onSaved: (value) => _apartmentType = value,
      focusNode: _formValidationManager
          .getFocusNodeForField('_apartmentTypeFormField'),
      values: ApartmentType.values,
      valueAsString: (value) => value.formattedString,
      decoration: const InputDecoration(
        filled: true,
        prefixIcon: Icon(Icons.house_outlined),
        labelText: "Apartment type",
      ),
    );
  }

  FormField<ComfortLevel> get _comfortLevelFormField {
    return FormField<ComfortLevel>(
      validator: _formValidationManager.wrapValidator(
        '_comfortLevelFormField',
        (value) => DataValidator.required(value),
      ),
      onSaved: (value) => _comfortLevel = value,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (fieldState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MaterialButton(
            padding: const EdgeInsets.all(0),
            onPressed: () async {
              FocusManager.instance.primaryFocus?.unfocus();

              /// if the user taps on the mask behind the dialog, then the
              /// future below completes with the null value.
              final selectedLevel = await showDialog<ComfortLevel>(
                context: context,
                builder: (_) => SimpleDialog(
                  title: const Text('Select a level of comfort'),
                  children: [
                    SimpleDialogOption(
                      onPressed: () =>
                          Navigator.pop(context, ComfortLevel.unfurnished),
                      child: Text(ComfortLevel.unfurnished.formattedString),
                    ),
                    SimpleDialogOption(
                      onPressed: () =>
                          Navigator.pop(context, ComfortLevel.semiFurnished),
                      child: Text(ComfortLevel.semiFurnished.formattedString),
                    ),
                    SimpleDialogOption(
                      onPressed: () =>
                          Navigator.pop(context, ComfortLevel.furnished),
                      child: Text(ComfortLevel.furnished.formattedString),
                    ),
                  ],
                ),
              );
              if (selectedLevel != null && selectedLevel != fieldState.value) {
                fieldState.didChange(selectedLevel);
              }
            },
            child: AbsorbPointer(
              child: Theme(
                data: fieldState.hasError
                    ? ThemeData().copyWith(
                        colorScheme: ThemeData()
                            .colorScheme
                            .copyWith(primary: const Color(0xffd32f2f)),
                        inputDecorationTheme: const InputDecorationTheme(
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xffd32f2f)),
                          ),
                        ),
                      )
                    : Theme.of(fieldState.context),
                child: TextField(
                  focusNode: _formValidationManager
                      .getFocusNodeForField('_comfortLevelFormField'),
                  readOnly: true,
                  showCursor: false,
                  decoration: InputDecoration(
                    filled: true,
                    prefixIcon: const Icon(Icons.category_outlined),
                    floatingLabelBehavior: (fieldState.value != null)
                        ? FloatingLabelBehavior.always
                        : null,
                    labelText: "Comfort level",
                    hintText: (fieldState.value != null)
                        ? fieldState.value!.formattedString
                        : null,
                    hintStyle: const TextStyle(color: Color(0xdd000000)),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 8),
            child: Text(
              fieldState.errorText ?? '',
              style: Theme.of(context)
                  .textTheme
                  .caption!
                  .copyWith(color: Theme.of(context).errorColor),
            ),
          ),
        ],
      ),
    );
  }

  ClearableTextFormField get _monthlyRentFormField {
    return ClearableTextFormField(
      validator: _formValidationManager.wrapValidator(
        '_monthlyRentFormField',
        (value) => DataValidator.textRequired(value),
      ),
      onSaved: (value) => _monthlyRent = value,
      focusNode:
          _formValidationManager.getFocusNodeForField('_monthlyRentFormField'),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        NumericTextInputFormatter(),
        LengthLimitingTextInputFormatter(6),
      ],
      decoration: _inputDecoration.copyWith(
        prefixIcon: const Icon(Icons.attach_money_outlined),
        labelText: "Monthly rent price",
      ),
    );
  }

  ClearableTextFormField get _nBedroomsFormField {
    return ClearableTextFormField(
      validator: _formValidationManager.wrapValidator(
        '_nBedroomsFormField',
        (value) => DataValidator.textRequired(value),
      ),
      onSaved: (value) => _nBedrooms = value,
      focusNode:
          _formValidationManager.getFocusNodeForField('_nBedroomsFormField'),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        NumericTextInputFormatter(),
        LengthLimitingTextInputFormatter(2),
      ],
      decoration: _inputDecoration.copyWith(
        prefixIcon: const Icon(Icons.bed_outlined),
        labelText: "Number of bedrooms",
      ),
    );
  }

  TextFormField get _noteFormField {
    return TextFormField(
      onSaved: (value) => _note = value,
      textInputAction: TextInputAction.newline,
      keyboardType: TextInputType.multiline,
      decoration: _inputDecoration.copyWith(
        labelText: 'Note (optional)',
        alignLabelWithHint: true,
      ),
      minLines: 4, // initial height

      /// If maxLines is set to null, there is no limit to the number of lines.
      /// The field sizes itself to the inner text and the wrap is enabled.
      maxLines: null,
      maxLength: 400,
    );
  }

  ElevatedButton get _formSubmitBtn {
    return ElevatedButton.icon(
      onPressed: () async {
        if (_formKey.currentState!.validate()) {
          _formKey.currentState!.save();
          final location = _locationAddress!;
          final data = ApartmentModel(
            name: _name!,
            reporterName: _reporterName!,
            formattedAddress: location.formattedAddress,
            addressComponents: AddressComponents(
              level1Id: location.level1.id,
              level2Id: location.level2.id,
              level3Id: location.level3?.id,
              route: location.route,
            ),
            type: _apartmentType!,
            comfortLevel: _comfortLevel!,
            monthlyRent: NumberFormat().parse(_monthlyRent!).toInt(),
            nBedrooms: int.parse(_nBedrooms!),
            note: _note,
            creatorId: FirebaseAuth.instance.currentUser!.uid,
            createdAt: Timestamp.now(),
          );
          await ApartmentRepo.add(data).catchError((onErr) {
            debugPrint(onErr);
          });
          AlertService.showEphemeralSnackBar(
              'Your apartment is added successfully ✅');
          Navigator.pop(context);
        } else {
          _formValidationManager.erroredFields.first.focusNode.requestFocus();
          Scrollable.ensureVisible(
              _formValidationManager.erroredFields.first.focusNode.context!);
        }
      },
      icon: const Icon(Icons.cloud_done_outlined),
      label: const Text('Submit'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      onWillPop: () async {
        final result = await AlertService.showConfirmationDialog(
          content: const Text('Are you sure you want to discard any changes?'),
          confirmText: 'Discard',
        );
        return result;
      },
      child: Scrollbar(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...[
                  _nameFormField,
                  _reporterNameFormField,
                  _locationAddressFormField,
                  _apartmentTypeFormField,
                  _comfortLevelFormField,
                  _monthlyRentFormField,
                  _nBedroomsFormField,
                  _noteFormField,
                  _formSubmitBtn
                ].expand((widget) => [widget, const SizedBox(height: 16)])
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _formValidationManager.dispose();
  }
}

const _inputDecoration = InputDecoration(
  filled: true,
  helperText: '',
);
