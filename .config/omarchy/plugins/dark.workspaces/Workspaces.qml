import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "dark.workspaces"

  readonly property var barScreen: root.QsWindow.window ? root.QsWindow.window.screen : null
  readonly property string outputName: barScreen ? String(barScreen.name || "").toLowerCase() : ""
  readonly property bool hpMonitor: outputName.indexOf("hdmi-a-1") !== -1
    || outputName.indexOf("hp l1950") !== -1
    || outputName.indexOf("hewlett packard") !== -1
    || (barScreen && barScreen.geometry && barScreen.geometry.x < 0)

  function workspaceName(number) {
    return hpMonitor ? "HP-" + number : String(number)
  }

  function workspaceByName(name) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].name === name) return values[i]
    }

    return null
  }

  function workspaceNames() {
    var names = []
    for (var number = 1; number <= 10; number++) {
      names.push(workspaceName(number))
    }
    return names
  }

  function focusWorkspace(name) {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"name:" + name + "\" })"))
  }

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : root.workspaceNames().length
    columnSpacing: root.vertical ? 0 : Style.space(1)
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      model: root.workspaceNames()

      WidgetButton {
        required property string modelData

        readonly property var workspace: root.workspaceByName(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.name === modelData

        bar: root.bar
        text: focused ? "\uDB85\uDCFB" : (root.hpMonitor ? modelData : (modelData === "10" ? "0" : modelData))
        opacity: occupied || focused ? 1 : 0.5
        horizontalMargin: 6
        verticalPadding: 6
        fixedWidth: root.vertical ? root.barSize : (root.hpMonitor ? -1 : Style.space(20))
        fixedHeight: root.barSize
        onPressed: function() { root.focusWorkspace(modelData) }
      }
    }
  }
}
