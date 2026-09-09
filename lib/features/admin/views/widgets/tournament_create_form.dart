import '../../../tournament/models/tournament_model.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TournamentCreateForm extends StatefulWidget {
  final Tournament? tournament;
  const TournamentCreateForm({super.key, this.tournament});

  @override
  State<TournamentCreateForm> createState() => _TournamentCreateFormState();
}

class _TournamentCreateFormState extends State<TournamentCreateForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _feeController;
  late TextEditingController _maxPlayersController;
  late TextEditingController _rulesController;
  late TextEditingController _whatsappLinkController;
  List<_PrizeInput> _prizeInputs = [];
  
  DateTime? _startDate;
  DateTime? _registrationEndDate;
  late TournamentStatus _status;
  late TournamentType _type;
  late bool _isFree;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.tournament?.title ?? '');
    _descriptionController = TextEditingController(text: widget.tournament?.description ?? '');
    _feeController = TextEditingController(text: (widget.tournament?.entryFee ?? 0).toString());
    _maxPlayersController = TextEditingController(text: (widget.tournament?.maxPlayers ?? 32).toString());
    _rulesController = TextEditingController(text: widget.tournament?.rules.join('\n') ?? '');
    _whatsappLinkController = TextEditingController(text: widget.tournament?.whatsappGroupLink ?? '');
    
    if (widget.tournament?.prizes != null && widget.tournament!.prizes.isNotEmpty) {
      _prizeInputs = widget.tournament!.prizes.entries
          .map((e) => _PrizeInput(label: e.key, value: e.value))
          .toList();
    } else if (widget.tournament == null) {
      _prizeInputs = [
        _PrizeInput(label: '1st Place', value: ''),
        _PrizeInput(label: '2nd Place', value: ''),
      ];
    }

    _startDate = widget.tournament?.startDate;
    _registrationEndDate = widget.tournament?.registrationEndDate;
    _status = widget.tournament?.status ?? TournamentStatus.upcoming;
    _type = widget.tournament?.type ?? TournamentType.knockout;
    _isFree = widget.tournament?.isFree ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _feeController.dispose();
    _maxPlayersController.dispose();
    _rulesController.dispose();
    _whatsappLinkController.dispose();
    for (var input in _prizeInputs) {
      input.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                (widget.tournament == null ? 'Create New Tournament' : 'Edit Tournament').toUpperCase(),
                style: GoogleFonts.rajdhani(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'TOURNAMENT TITLE',
                  labelStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'DESCRIPTION',
                  labelStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                maxLines: 3,
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _whatsappLinkController,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'WHATSAPP GROUP LINK',
                  labelStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  hintText: 'https://chat.whatsapp.com/...',
                  prefixIcon: const Icon(Icons.link, size: 18),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _maxPlayersController,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'MAX PLAYERS',
                        labelStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<TournamentStatus>(
                      value: _status,
                      dropdownColor: AppTheme.cardBackground,
                      decoration: InputDecoration(
                        labelText: 'STATUS',
                        labelStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      items: TournamentStatus.values
                          .map((s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase(), style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1))))
                          .toList(),
                      onChanged: (val) => setState(() => _status = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TournamentType>(
                value: _type,
                dropdownColor: AppTheme.cardBackground,
                decoration: InputDecoration(
                  labelText: 'TOURNAMENT TYPE',
                  labelStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                items: TournamentType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.name.toUpperCase(), style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1))))
                    .toList(),
                onChanged: (val) => setState(() => _type = val!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'START DATE',
                        style: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      subtitle: Text(
                        _startDate == null ? 'Not Set' : _startDate!.toString().split(' ')[0],
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                      trailing: const Icon(Icons.calendar_today, size: 18, color: AppTheme.primaryGold),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          builder: (context, child) => Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: Theme.of(context).colorScheme.copyWith(
                                    primary: AppTheme.primaryGold,
                                    onPrimary: Colors.black,
                                  ),
                            ),
                            child: child!,
                          ),
                        );
                        if (date != null) setState(() => _startDate = date);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'REG. END DATE',
                        style: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      subtitle: Text(
                        _registrationEndDate == null ? 'Not Set' : _registrationEndDate!.toString().split(' ')[0],
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                      trailing: const Icon(Icons.timer, size: 18, color: AppTheme.primaryGold),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _registrationEndDate ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          builder: (context, child) => Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: Theme.of(context).colorScheme.copyWith(
                                    primary: AppTheme.primaryGold,
                                    onPrimary: Colors.black,
                                  ),
                            ),
                            child: child!,
                          ),
                        );
                        if (date != null) setState(() => _registrationEndDate = date);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text(
                  'IS FREE TOURNAMENT?',
                  style: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                value: _isFree,
                activeColor: AppTheme.primaryGold,
                onChanged: (val) => setState(() => _isFree = val),
              ),
              if (!_isFree)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: TextFormField(
                    controller: _feeController,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'ENTRY FEE (BDT)',
                      labelStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                'TOURNAMENT RULES',
                style: GoogleFonts.rajdhani(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _rulesController,
                decoration: InputDecoration(
                  hintText: 'Enter rules, one per line...',
                  hintStyle: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13),
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.all(12),
                ),
                maxLines: 5,
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PRIZE POOL',
                    style: GoogleFonts.rajdhani(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _prizeInputs.add(_PrizeInput())),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      'ADD PRIZE',
                      style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ),
                ],
              ),
              ..._prizeInputs.map((input) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: input.labelController,
                            style: GoogleFonts.poppins(fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'PRIZE LABEL',
                              labelStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.1),
                              hintText: 'e.g. 1st Place',
                              hintStyle: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: input.valueController,
                            style: GoogleFonts.poppins(fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'PRIZE AMOUNT',
                              labelStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.1),
                              hintText: 'e.g. 500 BDT',
                              hintStyle: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 22),
                          onPressed: () => setState(() {
                            input.dispose();
                            _prizeInputs.remove(input);
                          }),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: Text(
                    (widget.tournament == null ? 'Launch Tournament' : 'Update Tournament').toUpperCase(),
                    style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final rules = _rulesController.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final prizes = <String, String>{};
      for (var input in _prizeInputs) {
        if (input.labelController.text.isNotEmpty) {
          prizes[input.labelController.text.trim()] = input.valueController.text.trim();
        }
      }

      final tournament = Tournament(
        id: widget.tournament?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        status: _status,
        type: _type,
        startDate: _startDate,
        registrationEndDate: _registrationEndDate,
        entryFee: int.tryParse(_feeController.text) ?? 0,
        isFree: _isFree,
        maxPlayers: int.tryParse(_maxPlayersController.text) ?? 32,
        registeredPlayers: widget.tournament?.registeredPlayers ?? [],
        rules: rules,
        prizes: prizes,
        whatsappGroupLink: _whatsappLinkController.text.trim().isEmpty ? null : _whatsappLinkController.text.trim(),
      );

      if (widget.tournament == null) {
        await DatabaseService().addTournament(tournament);
      } else {
        await DatabaseService().updateTournament(tournament);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              (widget.tournament == null ? 'Tournament Created Successfully!' : 'Tournament Updated Successfully!').toUpperCase(),
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    }
  }
}

class _PrizeInput {
  final TextEditingController labelController;
  final TextEditingController valueController;

  _PrizeInput({String label = '', String value = ''})
      : labelController = TextEditingController(text: label),
        valueController = TextEditingController(text: value);

  void dispose() {
    labelController.dispose();
    valueController.dispose();
  }
}
