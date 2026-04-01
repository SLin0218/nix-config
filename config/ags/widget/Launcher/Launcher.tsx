import { Astal, Gtk, Gdk } from "ags/gtk4";
import app from "ags/gtk4/app";
import Apps from "gi://AstalApps";
import Hyprland from "gi://AstalHyprland"
import { createState, With, Accessor } from "ags";
import GLib from "gi://GLib";
import Pango from "gi://Pango?version=1.0";

// 用于全局存储输入框的引用
let entryRef: Gtk.Entry | null = null;

function AppItem({
  app,
  onClick,
  selectedIndex,
  index
}: {
  app: Apps.Application;
  onClick: () => void;
  selectedIndex: Accessor<number>;
  index: number;
}) {
  const selected = selectedIndex.as((s) => s === index);

  return (
    <button
      cssClasses={selected.as((s) => (s ? ["app-item", "selected"] : ["app-item"]))}
      onClicked={onClick}
      $={(self) => {
        selectedIndex.subscribe(() => {
          if (selectedIndex.peek() === index) {
            GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
              // 通过 grab_focus 触发 ScrolledWindow 的自动滚动
              self.grab_focus();
              // 立即将焦点还给输入框，确保用户可以继续键入
              if (entryRef) entryRef.grab_focus();
              return GLib.SOURCE_REMOVE;
            });
          }
        });
      }}
    >
      <box>
        <image
          cssClasses={["app-icon"]}
          iconName={app.icon_name || "application-x-executable"}
          pixelSize={48}
        />
        <box orientation={Gtk.Orientation.VERTICAL} valign={Gtk.Align.CENTER}>
          <label
            cssClasses={["app-name"]}
            label={app.name}
            xalign={0}
            ellipsize={Pango.EllipsizeMode.END}
          />
          {app.description && (
            <label
              cssClasses={["app-description"]}
              label={app.description}
              xalign={0}
              ellipsize={Pango.EllipsizeMode.END}
            />
          )}
        </box>
      </box>
    </button>
  );
}

function ScrollList({
  list,
  selectedIndex,
  onHide
}: {
  list: Accessor<Array<Apps.Application>>,
  selectedIndex: Accessor<number>,
  onHide: () => void,
}) {
  return (
    <scrolledwindow
      cssClasses={["app-list"]}
      hscrollbarPolicy={Gtk.PolicyType.NEVER}
      vscrollbarPolicy={Gtk.PolicyType.EXTERNAL}
      vexpand
    >
      <box orientation={Gtk.Orientation.VERTICAL}>
        <With value={list}>
          {(items) => (
            <box orientation={Gtk.Orientation.VERTICAL}>
              {items.map((item: Apps.Application, index: number) => (
                <AppItem
                  app={item}
                  selectedIndex={selectedIndex}
                  index={index}
                  onClick={() => {
                    item.launch();
                    onHide();
                  }}
                />
              ))}
            </box>
          )}
        </With>
      </box>
    </scrolledwindow>
  );
}

export default function Launcher(gdkmonitor: Gdk.Monitor) {
  const apps = new Apps.Apps();
  const [text, setText] = createState("");
  const [list, setList] = createState(apps.fuzzy_query(""));
  const [selectedIndex, setSelectedIndex] = createState(0);

  const monitorId = app.get_monitors().indexOf(gdkmonitor);
  const winName = `launcher-${monitorId}`;

  text.subscribe(() => {
    const val = text.peek();
    const results = apps.fuzzy_query(val);
    setList(results);
    setSelectedIndex(0);
  });

  const onHide = () => {
    setText("");
    setSelectedIndex(0);
    app.toggle_window(winName);
  };

  const launchSelected = () => {
    const currentList = list.peek();
    const index = selectedIndex.peek();
    if (currentList[index]) {
      currentList[index].launch();
      onHide();
    }
  };

  const { TOP, BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor;

  return (
    <window
      name={winName}
      gdkmonitor={gdkmonitor}
      layer={Astal.Layer.OVERLAY}
      anchor={TOP | BOTTOM | LEFT | RIGHT}
      keymode={Astal.Keymode.EXCLUSIVE}
      application={app}
      visible={false}
      $={(self) => {
        const keyController = new Gtk.EventControllerKey();
        keyController.connect("key-pressed", (controller, keyval) => {
          if (keyval === Gdk.KEY_Escape) {
            onHide();
            return true;
          }
          return false;
        });
        self.add_controller(keyController);
      }}
    >
      <overlay>
        <button cssClasses={["button-padding"]} onClicked={onHide} hexpand vexpand />
        <box
          halign={Gtk.Align.CENTER}
          valign={Gtk.Align.CENTER}
          cssClasses={["launcher"]}
          orientation={Gtk.Orientation.VERTICAL}
        >
          <box cssClasses={["search-box"]}>
            <image iconName="system-search-symbolic" />
            <entry
              hexpand
              placeholderText="Search Apps..."
              text={text}
              onActivate={launchSelected}
              $={(self) => {
                self.connect("changed", () => setText(self.text));
                entryRef = self;
                const keyController = new Gtk.EventControllerKey();
                keyController.connect("key-pressed", (controller, keyval) => {
                  const currentList = list.peek();
                  const index = selectedIndex.peek();
                  if (keyval === Gdk.KEY_Down) {
                    setSelectedIndex((index + 1) % currentList.length);
                    return true;
                  }
                  if (keyval === Gdk.KEY_Up) {
                    setSelectedIndex((index - 1 + currentList.length) % currentList.length);
                    return true;
                  }
                  return false;
                });
                self.add_controller(keyController);
              }}
            />
          </box>
          <box>
            <box>
              <ScrollList
                list={list}
                selectedIndex={selectedIndex}
                onHide={onHide}
              />
            </box>
            <box>
              1
            </box>
          </box>
        </box>
      </overlay>
    </window>
  );
}

export function toggleLauncher() {
  const hyprland = Hyprland.get_default()
  const monitor: Hyprland.Monitor | undefined = hyprland.get_monitors().find((monitor) => monitor.focused);
  if (monitor) {
    app.toggle_window(`launcher-${monitor.id}`);
  }
}
