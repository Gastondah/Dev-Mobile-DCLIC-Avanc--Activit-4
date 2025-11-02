import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Nécessaire pour json.decode(reponse.body)

void main() {
  runApp(const MonApplication());
}

// --- CLASSE 1 : MonApplication ---
class MonApplication extends StatelessWidget {
  const MonApplication({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Application Météo', // Le titre de l'application
      theme: ThemeData(
        primarySwatch: Colors.blue, // Couleur principale bleue
      ),
      home: const PrevisionInterface(), // La page d'accueil
    );
  }
}

// --- CLASSE 2 : PrevisionInterface (Suite dans la section suivante) ---

// --- CLASSE 2 : PrevisionInterface ---
class PrevisionInterface extends StatefulWidget {
  const PrevisionInterface({super.key});

  @override
  State<PrevisionInterface> createState() => _PrevisionInterfaceState();
}

class _PrevisionInterfaceState extends State<PrevisionInterface> {
  // Clé API que vous avez récupérée d'OpenWeather
  final String apiKey = "83342690b0e4bf46e8cf550fede04244";
  // Contrôleur pour le champ de texte de la ville
  final TextEditingController _villeController = TextEditingController();

  // Variable pour suivre l'état de chargement
  bool _isLoading = false;

  // Stocke les données météo récupérées (peut être nul initialement)
  Map<String, dynamic>? _DonneesMeteo;

  // Méthode pour appeler l'API OpenWeather
  Future<void> _recupererDonnees() async {
    // 1. Début du chargement
    setState(() {
      _isLoading = true; // Affiche l'icône de chargement
      _DonneesMeteo = null;
    });

    final String ville = _villeController.text;
    if (ville.isEmpty) {
      // Gérer le cas où l'utilisateur n'entre pas de ville
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // URL de l'API (utilisation des unités métriques)
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?q=$ville&appid=$apiKey&units=metric',
    );

    try {
      // 2. Exécution de la requête HTTP
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Succès: décodage de la réponse JSON
        final Map<String, dynamic> donnees = json.decode(
          response.body,
        ); // Utilisation de json.decode

        // 3. Mise à jour de l'état avec les données et fin du chargement
        setState(() {
          _DonneesMeteo = donnees; // Stockage des données
          _isLoading = false; // Masque l'icône de chargement
        });
      } else {
        // Erreur de l'API (ville non trouvée, clé invalide, etc.)
        // afficher un message d'erreur ici pour améliorer l'application
        setState(() {
          _isLoading = false;
          _DonneesMeteo = {
            'error': 'Erreur lors de la récupération : ${response.statusCode}',
          };
        });
      }
    } catch (e) {
      // Erreur réseau ou de décodage
      setState(() {
        _isLoading = false;
        _DonneesMeteo = {'error': 'Erreur réseau: $e'};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prévisions météo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // Champ de texte pour la ville
            TextField(
              controller: _villeController,
              decoration: const InputDecoration(hintText: 'Entrez une ville'),
              onSubmitted: (_) =>
                  _recupererDonnees(), // Optionnel: lancer la recherche sur 'Entrée'
            ),
            const SizedBox(height: 20),
            // Bouton 'Obtenir la météo'
            ElevatedButton(
              onPressed: _recupererDonnees, // Déclenche la méthode
              child: const Text('Obtenir la météo'),
            ),
            const SizedBox(height: 40),

            // Affichage conditionnel
            _isLoading
                ? const CircularProgressIndicator() // Affiche l'icône de chargement si _isLoading est true [cite: 109]
                : _DonneesMeteo == null
                ? const Text('Aucune donnée météo disponible') // État initial
                : _DonneesMeteo!.containsKey('error')
                ? Text(_DonneesMeteo!['error']) // Affichage d'une erreur
                : DonneesMeteoWidget(
                    donneesMeteo: _DonneesMeteo!,
                  ), // Affichage des données via le widget dédié
          ],
        ),
      ),
    );
  }
}
// --- CLASSE 3 : DonneesMeteoWidget (Suite dans la section suivante) ---

// --- CLASSE 3 : DonneesMeteoWidget ---
class DonneesMeteoWidget extends StatelessWidget {
  // Elle reçoit les données en paramètre
  final Map<String, dynamic> donneesMeteo;

  const DonneesMeteoWidget({super.key, required this.donneesMeteo});

  @override
  Widget build(BuildContext context) {
    // Extraction des données de la Map (JSON décodé)
    final double temperatureK = donneesMeteo['main']['temp'];
    // Conversion de Kelvin à Celsius : C = K - 273.15
    final double temperatureC = temperatureK - 273.15;

    // La description est souvent dans une liste 'weather'
    final String description = donneesMeteo['weather'][0]['description'];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Affiche la température en Celsius
        Text(
          'Température: ${temperatureC.toStringAsFixed(1)} °C',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        // Affiche la description
        Text('Description: $description', style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}
