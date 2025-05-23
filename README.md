# Dragsheet: Bouncy, Fun, & Draggable ✨

Simple Flutter package for creating bouncy, fun, and most importantly *draggable* sheets.

Developed because I wanted this for my own app, was familiar with the React Native versions of this, but couldn't find a matching one in the Flutter ecosystem.

## Examples

<table>
  <tr>
    <td>
      <img
        src="https://github.com/mattrltrent/random_assets/blob/main/ex-ezgif.com-video-to-gif-converter.gif?raw=true"
        alt="demo gif 1"
        height="400px"
      />
    </td>
    <td>
      <img
        src="https://github.com/mattrltrent/random_assets/blob/main/ex2-ezgif.com-video-to-gif-converter-2.gif?raw=true"
        alt="demo gif 2"
        height="400px"
      />
    </td>
    <td>
      <img
        src="https://github.com/mattrltrent/random_assets/blob/main/ex3-ezgif.com-video-to-gif-converter.gif?raw=true"
        alt="demo gif 3"
        height="400px"
      />
    </td>
  </tr>
</table>

This demo "sign up" [blurry sheet](https://github.com/mattrltrent/dragsheet/blob/main/example/lib/demo_sheet.dart) is not included with the package. I created it to demonstrate what you _are capable of doing_ with the `dragsheet` package.

## Usage

1. Initialize the controller.
    ```dart
    final controller = DragSheetController();
    ```

2. Open `YourWidget` via the controller.
    ```dart
    controller.show(
        context,
        (ctx) => YourWidget(),
    ),
    ```

3. If you want to close the sheet, use the controller.
    ```dart
    controller.close();
    ```

4. If you want to listen to the state of the sheet, use the controller.
    ```dart
    controller.addListener(() {
        print(controller.isOpen);
    });
    ```

5. Remember to `dispose` of the controller when you're done with it.
    ```dart
    @override
    void dispose() {
        super.dispose();
        controller.dispose();
    }
    ```

6. If you care about customization, you won't be disapointed. However, the defaults should be solid enough. The main property to know about is `shrinkWrap`. If you want your sheet to shrink to the size of the child you provide it, make this `true`.
    ```dart
    void show(
        BuildContext context,
        WidgetBuilder builder, {
        bool shrinkWrap = false,
        double minScale = 0.85,
        double maxScale = 1.0,
        double minRadius = 0.0,
        double maxRadius = 30.0,
        double minOpacity = 0.0,
        double maxOpacity = 0.5,
        Duration entranceDuration = const Duration(milliseconds: 200),
        Duration exitDuration = const Duration(milliseconds: 200),
        Duration gestureFadeDuration = const Duration(milliseconds: 200),
        Duration programmaticFadeDuration = const Duration(milliseconds: 200),
        double effectDistance = 220.0,
        BgOpacity? bgOpacity,
        double swipeVelocityMultiplier = 2.5,
        double swipeAccelerationThreshold = 50.0,
        double swipeAccelerationMultiplier = 12.0,
        double swipeMinVelocity = 1000.0,
        double swipeMaxVelocity = 10000.0,
        double swipeFriction = 0.09,
        VoidCallback? onShow,
        VoidCallback? onDismiss,
        Duration opacityDuration = const Duration(milliseconds: 200),
    })
    ```