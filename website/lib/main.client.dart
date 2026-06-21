import 'package:jaspr/client.dart';

import 'main.client.options.dart';

/// Client entrypoint: hydrates every `@client` island that was pre-rendered
/// on the server.
void main() {
  Jaspr.initializeApp(options: defaultClientOptions);
  runApp(const ClientApp());
}
