import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_options.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dragon_ball_app/main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Character {
  final int id;
  final String name;
  final String image;

  Character({required this.id, required this.name, required this.image});

  // Factory para converter JSON -> Objeto
  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(id: json['id'], name: json['name'], image: json['image']);
  }

  // Método para converter Objeto -> JSON
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'image': image};
  }
}

class ApiService {
  static const String _baseURL =
      'https://dragon-ball-api-055bab372b94.herokuapp.com/api';

  static Future<List<Character>> fetchCharacters() async {
    final uri = Uri.parse('$_baseURL/characters');
    final resp = await http.get(uri);

    if (resp.statusCode != 200) {
      throw Exception('Erro ao chamar API: ${resp.statusCode}');
    }

    List<dynamic> items = json.decode(resp.body);

    return items
        .map((e) => Character.fromJson(e))
        .whereType<Character>()
        .toList();
  }

  static Future<CharacterDetail> fetchCharacterById(int id) async {
    final url = Uri.parse("$_baseURL/characters/$id");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return CharacterDetail.fromJson(data);
    } else {
      throw Exception("Erro ao buscar personagem:${response.statusCode}");
    }
  }
}

class CharacterCarouselItem extends StatelessWidget {
  final Character character;
  const CharacterCarouselItem({super.key, required this.character});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ), // margem do card
      width: double.infinity, // ocupa toda largura disponível no carrossel
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16), // padding interno menor
          child: Column(
            children: [
              Expanded(
                child: Hero(
                  tag: 'character_${character.id}',
                  child: CachedNetworkImage(
                    imageUrl: character.image.isNotEmpty
                        ? character.image
                        : 'https://placehold.co/600x400?text=No%20Image',
                    fit: BoxFit.contain,
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                character.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ), // Aqui serão adicionados os elementos do personagem
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Character>> _futureCharacters;
  @override
  void initState() {
    super.initState();
    _futureCharacters = ApiService.fetchCharacters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("DRAGON BALL", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 228, 172, 16),
      ),
      body: FutureBuilder<List<Character>>(
        future: _futureCharacters,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          final chars = snapshot.data ?? [];
          if (chars.isEmpty) {
            return const Center(child: Text('Nenhum personagem encontrado'));
          }
          return Column(
            children: [
              Expanded(
                child: CarouselSlider.builder(
                  itemCount: chars.length,
                  itemBuilder: (context, index, realIdx) {
                    final ch = chars[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailScreen(character: ch),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                        child: CharacterCarouselItem(character: ch),
                      ),
                    );
                  },
                  options: CarouselOptions(
                    enlargeCenterPage: true,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 3),
                    enableInfiniteScroll: true,
                    viewportFraction: 0.68,
                    height: double.infinity,
                    //enlargeStrategy: CenterPageEnlargeStrategy.height,
                  ),
                ),
              ), //Aqui sera adicionado o carrossel
            ],
          );
        },
      ),
    );
  }
}

void main() {
  runApp(const DragonBallApp());
}

class DragonBallApp extends StatelessWidget {
  const DragonBallApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DRAGON BALL APP',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(centerTitle: true),
      ),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

class DetailScreen extends StatefulWidget {
  final Character character;
  const DetailScreen({super.key, required this.character});
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  @override
  Widget build(BuildContext context) {
    final character = widget.character;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          character.name,
          style: const TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: const Color.fromARGB(255, 228, 172, 16),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 320,
                child: Hero(
                  tag: 'character_${character.id}',
                  child: CachedNetworkImage(
                    imageUrl: character.image.isNotEmpty
                        ? character.image
                        : 'https://placehold.co/600x400?text=No%20Image',
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const SizedBox(
                      height: 320,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => const SizedBox(
                      height: 320,
                      child: Center(child: Icon(Icons.error, size: 48)),
                    ),
                  ),
                ),
              ),
              // Nome e ID
              const SizedBox(height: 16),
              Text(
                character.name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'ID: ${character.id}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 18),
              FutureBuilder(
                future: ApiService.fetchCharacterById(character.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Erro: ${snapshot.error}'));
                  }
                  final characterDetail = snapshot.data;
                  if (characterDetail == null) {
                    return const Center(
                      child: Text('Sem informações conhecidas'),
                    );
                  } else {
                    return Column(
                      children: [Text(characterDetail.description)],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CharacterDetail {
  final int id;
  final String name;
  final String ki;
  final String maxKi;
  final String race;
  final String gender;
  final String description;
  final String image;

  CharacterDetail({
    required this.id,
    required this.name,
    required this.ki,
    required this.maxKi,
    required this.race,
    required this.gender,
    required this.description,
    required this.image,
  });

  // Factory para converter JSON -> Objeto
  factory CharacterDetail.fromJson(Map<String, dynamic> json) {
    return CharacterDetail(
      id: json['id'],
      name: json['name'],
      ki: json['ki'],
      maxKi: json['maxKi'],
      race: json['race'],
      gender: json['gender'],
      description: json['description'],
      image: json['image'],
    );
  }
  // Método para converter Objeto -> JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ki': ki,
      'maxKi': maxKi,
      'race': race,
      'gender': gender,
      'description': description,
      'image': image,
    };
  }
}
