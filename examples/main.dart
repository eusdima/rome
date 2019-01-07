import 'dart:async';
import 'dart:io';

Future<String> getSchema() async {
  File schemaFile = new File('schema.gql');

  String content = await schemaFile.readAsString();

  return content;
}

List<String> parseSchemaTypes(String schema) {
  List<String> types = List<String>();

  StringBuffer type = StringBuffer('');
  num nestedCurlies = 0;
  bool insideType = false;

  for (num i = 0; i < schema.length; i++) {
    if (nestedCurlies == 0 && schema[i] == 't') {
      insideType = true;
    }

    if (insideType) {
      type.write(schema[i]);
    }

    if (schema[i] == '{') {
      nestedCurlies++;
    }

    if (schema[i] == '}') {
      nestedCurlies--;

      // Push type to the list
      if (nestedCurlies == 0) {
        types.add(type.toString());

        // Clear the string buffer
        type.clear();
        insideType = false;
      }
    }
  }

  return types;
}

class DepencecyGraph {
  Map<String, GraphQLType> namedTypes;

  List<String> predefinedTypes = [
    'Int',
    'Float',
    'String',
    'Boolean',
    'ID',
  ];

  // DepencecyGraph.fromTypes(List<GraphQLType> types) {
  //   namedTypes = Map<String, GraphQLType>();

  //   types.forEach((GraphQLType type) => namedTypes[type.name] = type);

  //   buildDependecyGraph();
  // }

  // void buildDependecyGraph() {
  //   namedTypes.forEach((name, type) {
  //     type.variables.forEach((variableName, variableType) {
  //       if (!predefinedTypes.contains(variableType)) {
  //         if (variableType.startsWith('[') && variableType.endsWith(']')) {
  //           variableType = variableType.substring(1, variableType.length - 1);

  //           type.dependencies[variableName] =
  //               GraphQLArray<GraphQLType>.fromType(namedTypes[variableType]);
  //         } else {
  //           type.dependencies[variableName] = namedTypes[variableType];
  //         }
  //       }
  //     });
  //   });
  // }
}

class GraphQLArray<T> {
  T type;

  GraphQLArray.fromType(T type) {
    this.type = type;
  }
}

class GraphQLFieldName {
  String name;

  GraphQLFieldName.fromString(String name) {
    this.name = name.split('(')[0];
  }
}

class GraphQLFieldType {
  bool scalar = true;
  bool required = false;
  String type = '';

  dynamic dependecy;

  GraphQLFieldType.fromString(String type) {
    this.type = type;

    if (type.endsWith('!')) {
      this.type = type.substring(0, type.length - 1);
      required = true;
    } else {
      this.type = type;
    }
  }
}

class GraphQLScalar {
  String name;

  static Map<String, String> builtInScalars = {
    'Int': 'int',
    'Float': 'float',
    'String': 'String',
    'Boolean': 'bool',
    'ID': "String"
  };

  GraphQLScalar.fromString(String string) {
    name = string;
  }

  String toString() {
    return builtInScalars[name];
  }

  static bool isScalar(String key) => builtInScalars.containsKey(key);
}

class GraphQLDependency {
  bool isScalar = true;
  bool isRequired = false;
  bool isArray = false;

  dynamic dependency;

  List<dynamic> arr = [];

  GraphQLDependency.fromString(String string) {
    parseValue(string);
  }

  void parseValue(String value) {
    if (value.endsWith('!')) {
      //isRequired = true;

      value = value.substring(0, value.length - 1);
    }

    if (value.startsWith('[')) {
      isArray = true;

      value = value.substring(1, value.length - 1);
    }

    if (GraphQLScalar.isScalar(value)) {
      dependency = GraphQLScalar.fromString(value);
    } else {
      dependency = value;
    }
  }

  bool validate(dynamic value) {
    return true;
  }

  String toString() =>
      isArray ? "List<${dependency.toString()}>" : "${dependency.toString()}";
}

class GraphQLArgument {
  GraphQLArgument.fromString(String string) {}
}

class GraphQLType {
  String name;
  Map<String, GraphQLDependency> dependencies;

  GraphQLType.fromString(String string) {
    name = '';
    dependencies = Map<String, GraphQLDependency>();

    for (String rawLine in string.split('\n')) {
      // Remove spaces from front and back
      String line = rawLine.trim();

      // skip testing for the first line
      if (!line.contains(':')) {
        // Check if the given line is the first line
        if (line.startsWith('type')) {
          // Remove type prefix
          String removedTypePrefix = line.replaceFirst('type', '');

          // Split from curly brachet after type name
          name = removedTypePrefix.trim().split(' ')[0];
        }

        continue;
      }

      // Returns an array with key and value as first and second elements
      List<String> keyAndValue = line.split(':');

      String key = keyAndValue[0].trim();
      String value = keyAndValue[1].trim();

      dependencies[key] = GraphQLDependency.fromString(value);
    }
  }

  String getStringifiedDependecies() {
    String result = "";

    dependencies.forEach((name, dependency) {
      result += "${dependency.toString()} ${name};\n ";
    });

    return result.replaceAll(' ', ' ');
  }

  String toString() {
    return """ class ${name} {
    ${getStringifiedDependecies()}

    } """;
  }
}

main() async {
  String schema = await getSchema();

  List<GraphQLType> types = parseSchemaTypes(schema)
      .map((String type) => GraphQLType.fromString(type))
      .toList();

  // DepencecyGraph dependencyGraph = DepencecyGraph.fromTypes(types);
  types.forEach((type) {
    print(type.toString());
  });
}

class Author {
  int id;
  String firstName;
  String lastName;
  List<Post> posts;
}

class Post {
  int id;
  String title;
  Author author;
  int votes;
}

class Query {
  List<Post> posts;
  Author author;
}

class Eus {
  String id;
  String firstName;
}
