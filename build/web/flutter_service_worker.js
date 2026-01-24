'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {".git/COMMIT_EDITMSG": "e112de47f4fac6c003eeae60959cc33d",
".git/config": "bc08cc52192c80658cb8cf2fb731df41",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/HEAD": "e9ab3b0883d4f511de9372d466b98c5d",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-commit.sample": "5029bfab85b1c39281aa9697379ea444",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/index": "004e114c496a9f1c7d5a204152e76a10",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "a85ad1a3f41f07252e8562551d4ec918",
".git/logs/refs/heads/gh-pages": "0d6d2f2a7dcefb40f26eac0851d275a8",
".git/logs/refs/heads/vercel-deploy": "22b737dff3542edc1b9ba5ec8af22880",
".git/objects/02/7b8456ea7d1f9b90a11add0c000dd89f36b5bc": "cab6cb77e17a9fe11103423e52a6fa6f",
".git/objects/03/1b5309ed4c256f68aaed46ee4cc4a7f52fa9ba": "86beddc67efe522666d0da4d37d15ceb",
".git/objects/05/21273e9444ea916460b1610b6e4b04aabc901f": "eb7b8ccde74998f16b2446042a89805a",
".git/objects/0a/22327a6a27498d6ceb2d2eba6d9cef731c5a11": "3bf37fcbf323b21e6c3147230b1c0bd7",
".git/objects/0f/16792b9fc67850ae1ed4f165f2c43218b0f15a": "533dafdf5f7a8861d6a5a886dd24e9c4",
".git/objects/14/8cabcad4d96c0de5f77831582ef36ba7249635": "61abc1d7f323a84179ec9b5233536503",
".git/objects/16/5da67191b73406e15fc3e6cf7cda3c195dc735": "86cfac30d97fb45bba2f4417782645d6",
".git/objects/17/90fa8d9e26421c05b9c4481e42c92adf02661c": "14713de26d700ae6e4148ba8a128cdc0",
".git/objects/1e/25fb4841dbfcbc6e4fa75d9417a4113ba250bc": "e91280155bc02e320c2a664e7fefc7b5",
".git/objects/20/1afe538261bd7f9a38bed0524669398070d046": "82a4d6c731c1d8cdc48bce3ab3c11172",
".git/objects/23/557800f53181be525680292ce1a1995ef7bef6": "665a9467f9d23cb2fa1921c243bb8530",
".git/objects/2b/dcc7b71006e80994fd9e929470816edede4cf0": "cc998aa0ebf2b4884f374c3781e5b5e2",
".git/objects/32/aa3cae58a7432051fc105cc91fca4d95d1d011": "4f8558ca16d04c4f28116d3292ae263d",
".git/objects/33/fdece773563911bd296e03e1c7e8b52a891be8": "c8835277b4adf63efa90e59a4f650021",
".git/objects/3a/7525f2996a1138fe67d2a0904bf5d214bfd22c": "ab6f2f6356cba61e57d5c10c2e18739d",
".git/objects/3a/bf18c41c58c933308c244a875bf383856e103e": "30790d31a35e3622fd7b3849c9bf1894",
".git/objects/48/4e6373ed2167ea9c0d2d1115fbc4fe081a853a": "85ad14ac1973757cc0a63e235b8870df",
".git/objects/4c/a0ff80527a8c62400f4ec10fb14e1d5bb1a664": "41b77b9032cb65a8c179f6a96460088e",
".git/objects/56/734ea21fd457b736f2cb41bc7f25c0767d8242": "62b87e075ad040d331ab120ca8683bb1",
".git/objects/5d/15fadf1864d70c7184fca7d3efde79cdf68af5": "79a44d8578cc18e3add64aa6a97f0da0",
".git/objects/6a/63b25c7a5d7cbc7f3a4e15b50456eff8a61207": "94dfc72f7c718cad89630ced7849d815",
".git/objects/6a/7b2af9be0defb4d9512fa07ff71d5dc3c09ada": "89a5fb3a47004bb74219112beb03344c",
".git/objects/6b/e909fbf40b23748412f0ea89bf0fae827ed976": "5f118419157d9534688915220cc803f7",
".git/objects/6f/586a56981c720869459abd32fd82e0a899f1a5": "ce7c11b21968e571565de213a17f3213",
".git/objects/82/f16da75c4b878e157309e2036f3c75be793ff1": "5206c6ade124455f3606ecd59d041c38",
".git/objects/84/0516208d35dcb4298847ab835e2ef84ada92fa": "36a4a870d8d9c1c623d8e1be329049da",
".git/objects/86/d111f09a93cccfa0011858c519a823e7dafef7": "9a15839a59b5f501fbf7b9824c4b6f84",
".git/objects/88/cfd48dff1169879ba46840804b412fe02fefd6": "e42aaae6a4cbfbc9f6326f1fa9e3380c",
".git/objects/8a/aa46ac1ae21512746f852a42ba87e4165dfdd1": "1d8820d345e38b30de033aa4b5a23e7b",
".git/objects/8f/368292a70675725b4d450fb31a7af7e7a2465c": "f772b016eabfd2336c517d3cfb18602d",
".git/objects/90/bcfcf0a77ab618a826db0fd8b0942963b653af": "fc109675cdf1233dd6599a4c3c0a7a69",
".git/objects/98/57c9b3b0448c92818efc5fda0f206b21914168": "ecbde07c564dabbec0f249821051b8af",
".git/objects/99/56d3d52e3fc8a4b0c5f6c58aed45dcccb5715b": "90f709134c246cc86b72d09d0fc2fac9",
".git/objects/9b/df503e3f447aaa719ba73173a17f4c101417ae": "300ef036c4ff69d996ee719641ea1425",
".git/objects/9e/26dfeeb6e641a33dae4961196235bdb965b21b": "304148c109fef2979ed83fbc7cd0b006",
".git/objects/a2/c2c501d92cade4609fbff2a20d058036a0f07d": "5799cad65f96fe00122233a5625d5041",
".git/objects/a5/3efdf92300d180241adcd14d81d15a734c4e08": "cdce04155deb291d95d5b2a8a45a186e",
".git/objects/a9/46fb5a36fac919e637569c2e4c4d78f434990a": "8942fc079fabe95137253a063c5b01e2",
".git/objects/af/1b132654c2aa86837a27e14f054f9c3692d23d": "54adf2f20e88485ea2dc8c46e860fe78",
".git/objects/b1/27a568c52992b6b1f6993b66e057ed6e3db4b2": "9bcb553918d6042576a6476f0d8eab95",
".git/objects/b7/49bfef07473333cf1dd31e9eed89862a5d52aa": "36b4020dca303986cad10924774fb5dc",
".git/objects/b9/2a0d854da9a8f73216c4a0ef07a0f0a44e4373": "f62d1eb7f51165e2a6d2ef1921f976f3",
".git/objects/ba/b06115d1ac70dab989fd6f14e2c6e73911cbbf": "f9a9f93cffc81d1ae130de95c8603e10",
".git/objects/bf/5423b34ad5c82ba767721b42809c24c8fecb99": "0cbe16b0e4dfb28595e5e15407010190",
".git/objects/c6/8f44ee9388424815d2f0cdb571c7d78e5bbb92": "f77ab9e815a4ba4a86a42a6d81ec0404",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/d4/97a60fae4dcdf729d3387566a8e274b5a3611a": "74d795896c40e831db1d356260bfdbce",
".git/objects/d4/e10b3a9302a8e246127216b1c5b2594b6b4efe": "4e1b696bad48393c3d7bcddfc0775a23",
".git/objects/d6/9c56691fbdb0b7efa65097c7cc1edac12a6d3e": "868ce37a3a78b0606713733248a2f579",
".git/objects/d7/29d3b3f3640e22fa6aed23ad7ddefb998b0b8b": "7f57dffa2155c39cb52067f2f0ee8220",
".git/objects/da/4f7d2479ea369e0bff1e562d4747217ec901a8": "84c163badf4a2e0b9a4596c28b8f9c47",
".git/objects/db/47fc2329b13c9c744bebab570f236d4543ee73": "4bf3567fd66f9808a5b526cd2df54512",
".git/objects/df/6be4b9b923e2d7a27bc27d8b318ebd2c430e2c": "6f53864d5bd1c04bd7ee62b2bdaf517f",
".git/objects/e6/9de29bb2d1d6434b8b29ae775ad8c2e48c5391": "c70c34cbeefd40e7c0149b7a0c2c64c2",
".git/objects/e9/3afc7d15dd9294e144dddf0e6379f2f52fac0a": "78521746542c9aa66f1fae0d44700d15",
".git/objects/eb/9b4d76e525556d5d89141648c724331630325d": "37c0954235cbe27c4d93e74fe9a578ef",
".git/objects/f2/04823a42f2d890f945f70d88b8e2d921c6ae26": "6b47f314ffc35cf6a1ced3208ecc857d",
".git/objects/f5/010cda95492006dae3638dfb01a8d0822a1e6a": "04eb9fcdf209b67f396e5ab84cb956e2",
".git/objects/fd/e3a106ec1dafe56e7fe0b81c697aeb988ae0e2": "1942d87b1ebf71ecf5306335c7660dce",
".git/objects/fe/63a2b9eabcbc02e62c79c1daac91e306de5132": "c954f753d33329ffa52af4c394c2b501",
".git/refs/heads/gh-pages": "a1583db16810f599ab27d91fa460b8f2",
".git/refs/heads/vercel-deploy": "e074208bf0fa755ad0903587af701c97",
"assets/AssetManifest.bin": "0b0a3415aad49b6e9bf965ff578614f9",
"assets/AssetManifest.bin.json": "a1fee2517bf598633e2f67fcf3e26c94",
"assets/AssetManifest.json": "99914b932bd37a50b983c5e7c90ae93b",
"assets/FontManifest.json": "7b2a36307916a9721811788013e65289",
"assets/fonts/MaterialIcons-Regular.otf": "f682e65e7f54f4411d4236722e270e01",
"assets/NOTICES": "1dd77646db632dc0c75abbb148be9fdf",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "5fda3f1af7d6433d53b24083e2219fa0",
"canvaskit/canvaskit.js.symbols": "48c83a2ce573d9692e8d970e288d75f7",
"canvaskit/canvaskit.wasm": "1f237a213d7370cf95f443d896176460",
"canvaskit/chromium/canvaskit.js": "87325e67bf77a9b483250e1fb1b54677",
"canvaskit/chromium/canvaskit.js.symbols": "a012ed99ccba193cf96bb2643003f6fc",
"canvaskit/chromium/canvaskit.wasm": "b1ac05b29c127d86df4bcfbf50dd902a",
"canvaskit/skwasm.js": "9fa2ffe90a40d062dd2343c7b84caf01",
"canvaskit/skwasm.js.symbols": "262f4827a1317abb59d71d6c587a93e2",
"canvaskit/skwasm.wasm": "9f0c0c02b82a910d12ce0543ec130e60",
"canvaskit/skwasm.worker.js": "bfb704a6c714a75da9ef320991e88b03",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "f31737fb005cd3a3c6bd9355efd33061",
"flutter_bootstrap.js": "0405ed11a8772e0ff623c895ca287f4f",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "dd7478dc4002f5b7b6f8aad799789083",
"/": "dd7478dc4002f5b7b6f8aad799789083",
"main.dart.js": "b913cb82775b3e375cdeaf649c6a88fb",
"manifest.json": "758606c67a2f7bb302d8a7591fc6c66e",
"nul": "d41d8cd98f00b204e9800998ecf8427e",
"vercel.json": "e08633c79448542c130949a5ab82051d",
"version.json": "ce7636a80668ac4d364ec248d0985e4b"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
