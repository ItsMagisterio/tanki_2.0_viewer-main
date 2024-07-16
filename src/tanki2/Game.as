package tanki2 {
    import alternativa.engine3d.core.Camera3D;
    import alternativa.engine3d.core.Object3D;
    import alternativa.physics.collision.CollisionDetector;
    import flash.display.Stage;
    import flash.display.Stage3D;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.ui.Keyboard;
    import flash.utils.Dictionary;
    import flash.utils.setTimeout;
    import tanki2.systems.objectcontrollers.ObjectControllersSystem;
    import tanki2.taskmanager.TaskManager;
    import tanki2.utils.GOListItem;
    import tanki2.utils.KeyboardListener;
    import tanki2.utils.objectpool.ObjectPool;
    import tanki2.maploader.MapLoader;
    import tanki2.maploader.MapObject;
    import tanki2.systems.gameobjectssystem.GameObjectsSystem;
    import tanki2.systems.physicssystem.PhysicsSystem;
    import tanki2.display.DebugPanel;
    import tanki2.systems.timesystem.TimeSystem;
    import tanki2.utils.GOList;
    import tanki2.vehicles.tank.Tank;
    import tanki2.vehicles.tank.TankResourcesLoader;
    import tanki2.vehicles.tank.TanksManager;
    import tanki2.systems.SystemTags;
    import tanki2.systems.SystemPriority;
    import tanki2.systems.rendersystem.RenderSystem;

    [Event(name="initComplete", type="tanki2.GameEvent")]
   
    public class Game extends EventDispatcher {
        private static var instance:Game;
        private var taskManager:TaskManager = new TaskManager();
        private var objectPool:ObjectPool = new ObjectPool();
        private var stage:Stage;
        private var stage3D:Stage3D;
        private var keyboardListener:KeyboardListener;
        private var mapObject:MapObject;
        private var debugPanel:DebugPanel = new DebugPanel();
        
        public var physicsSystem:PhysicsSystem;
        public var gameObjects:GOList = new GOList();
        public var gameObjectById:Dictionary = new Dictionary();
        public var tanksManager:TanksManager;
        public var renderSystem:RenderSystem;

        public function Game(stage:Stage, stage3D:Stage3D) {
            this.stage = stage;
            this.stage3D = stage3D;
            instance = this;
            loadMap("data/dxt1/maps/arena-a3d.tara");
            FogUtils.setFog("45:0xffac5a 135:0x786d5d 225:0x00355f 315:0x786d5d", 100, 40000, 0.5);
        }

        public static function getInstance():Game {
            return instance;
        }

        public function getStage():Stage {
            return this.stage;
        }

        public function getCollisionDetector():CollisionDetector {
            return this.physicsSystem.physicsScene.collisionDetector;
        }

        public function tick():void {
            this.taskManager.runTasks();
        }

        private function initKeyboardListeners():void {
            this.keyboardListener.addHandler(Keyboard.F, this.renderSystem.toggleCameraController);
        }

        public function getObjectPool():ObjectPool {
            return this.objectPool;
        }

        public function getObjectFromPool(objectClass:Class):Object {
            return this.objectPool.getObject(objectClass);
        }

        public function addGameObject(gameObject:GameObject):void {
            if (this.gameObjectById[gameObject.id] != null) {
                throw new Error("Object already exists");
            }
            this.gameObjectById[gameObject.id] = new GOListItem(gameObject);
            this.gameObjects.append(gameObject);
            gameObject.addToGame(this);
        }

        public function removeGameObject(gameObject:GameObject):void {
            if (this.gameObjects.remove(gameObject)) {
                gameObject.removeFromGame();
                delete this.gameObjectById[gameObject.id];
            }
        }

        private function loadMap(mapUrl:String):void {
            var mapLoader:MapLoader = new MapLoader();
            mapLoader.addEventListener(Event.COMPLETE, this.mapLoaded);
            mapLoader.loadMap(mapUrl);
        }

        private function mapLoaded(e:Event):void {
            var mapLoader:MapLoader = MapLoader(e.target);
            this.mapObject = new MapObject(mapLoader);
            createPhysicsSystem(mapLoader);
            loadTankResources();
        }

        public function currentTankChanged(tank:Tank):void {
            this.renderSystem.followCameraController.setTarget(tank);
            this.physicsSystem.getCollisionDetector().trackedBody = tank.chassis;
        }

        private function loadTankResources():void {
            var loader:URLLoader = new URLLoader();
            loader.addEventListener(Event.COMPLETE, this.onTankResourcesLoaded);
            loader.load(new URLRequest("data/tanks/data/TankResources.json"));
        }

        private function onTankResourcesLoaded(e:Event):void {
            var loader:URLLoader = URLLoader(e.target);
            var tankAndTurretsJson:Object = JSON.parse(loader.data);
            var tankResourcesLoader:TankResourcesLoader = new TankResourcesLoader(tankAndTurretsJson);
            tankResourcesLoader.addEventListener(Event.COMPLETE, this.onTankResourcesReady);
            tankResourcesLoader.load();
        }

        private function onTankResourcesReady(e:Event):void {
            var tankResourcesLoader:TankResourcesLoader = TankResourcesLoader(e.target);
            this.tanksManager = new TanksManager(tankResourcesLoader, this, this.debugPanel);
            createTasks();
            this.renderSystem.scene3D.setMapObject(this.mapObject);
        }

        private function createPhysicsSystem(mapLoader:MapLoader):void {
            var gravity:Number = -1000;
            this.physicsSystem = new PhysicsSystem(gravity, mapLoader.collisionPrimitives, this.debugPanel);
        }

        private function createTasks():void {
            this.keyboardListener = new KeyboardListener(this.stage);
            this.taskManager.addTask(new TimeSystem());
            this.taskManager.addTask(new ObjectControllersSystem(SystemPriority.OBJECT_CONTROLLERS, SystemTags.OBJECT_CONTROLLERS, this.gameObjects));
            this.taskManager.addTask(this.physicsSystem);
            this.taskManager.addTask(new GameObjectsSystem(this.gameObjects));
            this.renderSystem = new RenderSystem(this.stage, this.stage3D, this.debugPanel, this.tanksManager);
            this.taskManager.addTask(this.renderSystem);
            initKeyboardListeners();
            this.keyboardListener.addHandler(Keyboard.P, this.addTank);
            setTimeout(this.completeInit, 0);
        }

        private function addTank():void {
            var loader:URLLoader = new URLLoader();
            loader.addEventListener(Event.COMPLETE, this.onUserJsonLoaded);
            loader.load(new URLRequest("data/tanks/data/User.json"));
        }

        private function onUserJsonLoaded(e:Event):void {
            var loader:URLLoader = URLLoader(e.target);
            var userJson:Object = JSON.parse(loader.data);
            var userNickname:String = userJson.nickname;  // Извлекаем ник из данных JSON
            this.tanksManager.loadTanksFromJson(JSON.stringify(userJson));
            this.tanksManager.setOwnTank(userNickname);  // Используем извлечённый ник
        }

        private function completeInit():void {
            dispatchEvent(new GameEvent(GameEvent.INIT_COMPLETE));
        }
    }
}
