// ZOD-NAV-003: the deep-link inputs shared by the router, active-route and
// drawer tests, so one list defines what is valid and what is malformed.
import 'package:astro_mobile/src/navigation/app_route.dart';

/// Links that name `square`, in every accepted spelling. `Uri` lowercases a
/// scheme and a host, so `zodiann://Square` and `ZODIANN://square` resolve.
const squareLinks = <String>[
  '/square',
  '/square/',
  '/square?x=1',
  '/square#f',
  'zodiann:///square',
  'zodiann://square',
  'zodiann://square/',
  'zodiann://square?x=1',
  // go_router strips one trailing slash before any code sees the link, so a
  // doubled one after a host is the same link as zodiann://square/.
  'zodiann://square//',
  'zodiann://Square',
  'ZODIANN://square',
];

/// Both scheme spellings of every screen, with the screen each opens.
final Map<String, AppRoute> schemeLinks = {
  for (final route in AppRoute.values) ...{
    'zodiann://${route.name}': route,
    'zodiann:///${route.name}': route,
  },
};

/// Links that name no screen. Each must land on the wheel, never an error.
const malformedLinks = <String>[
  'zodiann:square',
  'zodiann:/square',
  '/Square',
  '/nope',
  '/wheel/extra',
  'zodiann://nope',
  'zodiann://square/extra',
  'zodiann://',
  'zodiann://nope/square',
  'zodiann://wheel/square',
  'zodiann:///Square',
  // One trailing slash is stripped by go_router; a second names no screen.
  'zodiann:///square//',
  '/square//',
  'https://example.com/square',
  '',
];
