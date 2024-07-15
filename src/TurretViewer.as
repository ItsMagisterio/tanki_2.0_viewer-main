package 
{
   import alternativa.engine3d.controllers.SimpleObjectController;
   import alternativa.engine3d.core.Camera3D;
   import alternativa.engine3d.core.Object3D;
   import alternativa.engine3d.loaders.ParserA3D;
   import alternativa.engine3d.materials.TextureMaterial;
   import alternativa.engine3d.objects.Mesh;
   import alternativa.engine3d.resources.ExternalTextureResource;
   import alternativa.engine3d.resources.Geometry;
   import alternativa.engine3d.resources.Resource;

   import flash.display.Sprite;
   import flash.display.Stage3D;
   import flash.display.StageAlign;
   import flash.display.StageScaleMode;
   import flash.events.Event;
   import flash.events.KeyboardEvent;
   import flash.net.URLLoader;
   import flash.net.URLLoaderDataFormat;
   import flash.net.URLRequest;

   public class TurretViewer extends Sprite
   {
      private var scene:Object3D = new Object3D();
      private var camera:Camera3D;
      private var stage3D:Stage3D;
      private var moveSpeed:Number = 0.5; // Adjust for sensitivity
      private var rotationSpeed:Number = 2; // Adjust for rotation sensitivity

      private var upPressed:Boolean = false;
      private var downPressed:Boolean = false;
      private var leftPressed:Boolean = false;
      private var rightPressed:Boolean = false;

      public function TurretViewer() 
      {
         stage.align = StageAlign.TOP_LEFT;
         stage.scaleMode = StageScaleMode.NO_SCALE;

         // Setup camera
         camera = new Camera3D(1, 1000);
         camera.view = new View(stage.stageWidth, stage.stageHeight, false, 0, 0, 4);
         addChild(camera.view);
         scene.addChild(camera);

         // Initial camera position
         camera.x = 0;
         camera.y = -30;
         camera.z = 35;
         camera.rotationX = -30 * Math.PI / 180;

         stage3D = stage.stage3Ds[0];
         stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContextCreate);
         stage3D.requestContext3D();

         // Add event listeners for camera control
         stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
         stage.addEventListener(Event.RESIZE, onResize);
         stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
         stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
      }

      private function onContextCreate(e:Event):void {
         stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreate);
         loadModel();
      }

      private function loadModel():void {
         var loaderA3D:URLLoader = new URLLoader();
         loaderA3D.dataFormat = URLLoaderDataFormat.BINARY;
         loaderA3D.load(new URLRequest("resources/turrets/thunder/m3/turret.a3d"));
         loaderA3D.addEventListener(Event.COMPLETE, onA3DLoad);
      }

      private function onA3DLoad(e:Event):void {
         var parser:ParserA3D = new ParserA3D();
         parser.parse((e.target as URLLoader).data);

         for each (var object:Object3D in parser.objects) {
            if (object is Mesh) {
               var mesh:Mesh = object as Mesh;
               uploadResources(mesh.getResources(false, Geometry));

               var texture:ExternalTextureResource = new ExternalTextureResource("resources/turrets/thunder/m3/diffuse.atf");
               mesh.getSurface(0).material = new TextureMaterial(texture);
               scene.addChild(mesh);
            }
         }
      }

      private function uploadResources(resources:Vector.<Resource>):void {
         for each (var resource:Resource in resources) {
            resource.upload(stage3D.context3D);
         }
      }

      private function onEnterFrame(e:Event):void {
         camera.render(stage3D);
         handleCameraMovement();
      }

      private function handleCameraMovement():void {
         if (upPressed) camera.y += moveSpeed;
         if (downPressed) camera.y -= moveSpeed;
         if (leftPressed) camera.x -= moveSpeed;
         if (rightPressed) camera.x += moveSpeed;

         // Rotate camera
         camera.rotationY += (mouseX - stage.stageWidth / 2) * 0.001 * rotationSpeed;
         camera.rotationX -= (mouseY - stage.stageHeight / 2) * 0.001 * rotationSpeed;

         // Center mouse position for continuous rotation
         stage.mouseX = stage.stageWidth / 2;
         stage.mouseY = stage.stageHeight / 2;
      }

      private function onKeyDown(e:KeyboardEvent):void {
         switch (e.keyCode) {
            case Keyboard.W: upPressed = true; break;
            case Keyboard.S: downPressed = true; break;
            case Keyboard.A: leftPressed = true; break;
            case Keyboard.D: rightPressed = true; break;
         }
      }

      private function onKeyUp(e:KeyboardEvent):void {
         switch (e.keyCode) {
            case Keyboard.W: upPressed = false; break;
            case Keyboard.S: downPressed = false; break;
            case Keyboard.A: leftPressed = false; break;
            case Keyboard.D: rightPressed = false; break;
         }
      }

      private function onResize(e:Event = null):void {
         camera.view.width = stage.stageWidth;
         camera.view.height = stage.stageHeight;
      }
   }
}
