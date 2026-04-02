import { Astal, Gtk, Gdk } from "ags/gtk4";
import app from "ags/gtk4/app";
import Apps from "gi://AstalApps";
import Hyprland from "gi://AstalHyprland"
import { createState, With, Accessor } from "ags";
import { execAsync } from "ags/process";
import GLib from "gi://GLib";
import Pango from "gi://Pango?version=1.0";

const [launcherMode, setLauncherMode] = createState<"app" | "cliphist">("app");

// 用于全局存储输入框的引用
let entryRef: Gtk.Entry | null = null;

// Cliphist Support
type ClipItem = {
  id: string;
  content: string;
  isImage: boolean;
};

async function fetchCliphist(): Promise<ClipItem[]> {
  try {
    // 过滤掉不可见的 Null 字符（\000），因为底层 GJS 解析 C-String 时遇到 Null 字符会直接截断后面的所有数据
    const list = await execAsync('bash -c "cliphist list | tr -d \'\\000\'"');
    return list.split("\n").filter(Boolean).map(line => {
      const match = line.match(/^(\d+)\s+(.*)$/);
      if (match) {
        const id = match[1];
        let content = match[2];
        const isImage = content.includes("[[ binary data");
        if (isImage) {
          const imgMatch = content.match(/\[\[ binary data ([\d.]+\s*[a-zA-Z]+)\s+[a-zA-Z]+\s+(\d+x\d+)\s*\]\]/);
          if (imgMatch) {
            content = `[ Image ${imgMatch[2]} ${imgMatch[1]} ]`;
          } else {
            content = content.replace(/\[\[ binary data (.*) \]\]/, "[ Image $1 ]");
          }
        }
        return { id, content, isImage };
      }
      return null;
    }).filter(Boolean) as ClipItem[];
  } catch (e) {
    return [];
  }
}

function CliphistItem({
  clip,
  onClick,
  selectedIndex,
  index
}: {
  clip: ClipItem;
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
              self.grab_focus();
              if (entryRef) entryRef.grab_focus();
              return GLib.SOURCE_REMOVE;
            });
          }
        });
      }}
    >
      <box orientation={Gtk.Orientation.VERTICAL} valign={Gtk.Align.CENTER}>
        <label
          cssClasses={["app-name"]}
          label={clip.isImage ? clip.content : clip.content.substring(0, 100).replace(/\n/g, " ")}
          xalign={0}
          ellipsize={Pango.EllipsizeMode.END}
        />
      </box>
    </button>
  );
}

function CliphistScrollList({
  list,
  selectedIndex,
  onHide
}: {
  list: Accessor<Array<ClipItem>>,
  selectedIndex: Accessor<number>,
  onHide: () => void,
}) {
  return (
    <scrolledwindow
      cssClasses={["app-list"]}
      hscrollbarPolicy={Gtk.PolicyType.NEVER}
      vscrollbarPolicy={Gtk.PolicyType.EXTERNAL}
      vexpand
      $={(self) => {
        self.set_size_request(300, -1);
      }}
    >
      <box orientation={Gtk.Orientation.VERTICAL}>
        <With value={list}>
          {(items: ClipItem[]) => (
            <box orientation={Gtk.Orientation.VERTICAL}>
              {items.map((item: ClipItem, index: number) => (
                <CliphistItem
                  clip={item}
                  selectedIndex={selectedIndex}
                  index={index}
                  onClick={() => {
                    onHide();
                    execAsync(`bash -c "cliphist decode ${item.id} | wl-copy"`).catch(err => {
                      console.error("Failed to copy", err);
                    });
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

  const [clipList, setClipList] = createState<ClipItem[]>([]);
  const [clipSelectedIndex, setClipSelectedIndex] = createState(0);
  const [clipFiltered, setClipFiltered] = createState<ClipItem[]>([]);
  const [previewImage, setPreviewImage] = createState<string | null>(null);
  const [previewText, setPreviewText] = createState<string | null>(null);

  const loadPreviewFor = (index: number, filtered: ClipItem[]) => {
    const item = filtered[index];
    if (item && item.isImage) {
      setPreviewText(null);
      const currentPath = `/tmp/cliphist-preview-${item.id}.png`;
      execAsync(`bash -c "cliphist decode ${item.id} > ${currentPath}"`).then(() => {
        setPreviewImage(currentPath);
      }).catch(() => {
        setPreviewImage(null);
      });
    } else if (item) {
      setPreviewImage(null);
      setPreviewText(""); // trigger Loading
      execAsync(`bash -c "cliphist decode ${item.id} | tr -d '\\000'"`).then((output) => {
        setPreviewText(output || " ");
      }).catch(() => {
        setPreviewText("Failed to decode cliphist item");
      });
    } else {
      setPreviewImage(null);
      setPreviewText("No content selected");
    }
  };

  launcherMode.subscribe(() => {
    const m = launcherMode.peek();
    if (m === "cliphist") {
      fetchCliphist().then(items => {
        setClipList(items);
        setClipFiltered(items);
        setClipSelectedIndex(0);
        loadPreviewFor(0, items);
      });
    }
  });

  clipSelectedIndex.subscribe(() => {
    const mode = launcherMode.peek();
    if (mode !== "cliphist") return;
    loadPreviewFor(clipSelectedIndex.peek(), clipFiltered.peek());
  });

  const monitorId = app.get_monitors().indexOf(gdkmonitor);
  const winName = `launcher-${monitorId}`;

  text.subscribe(() => {
    const val = text.peek();
    const mode = launcherMode.peek();
    if (mode === "app") {
      const results = apps.fuzzy_query(val);
      setList(results);
      setSelectedIndex(0);
    } else {
      const items = clipList.peek();
      const results = items.filter(item => item.content.toLowerCase().includes(val.toLowerCase()));
      setClipFiltered(results);
      setClipSelectedIndex(0);
      loadPreviewFor(0, results);
    }
  });

  const onHide = () => {
    setText("");
    setSelectedIndex(0);
    setClipSelectedIndex(0);
    setPreviewImage(null);
    setPreviewText(null);
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

        self.connect("notify::visible", () => {
          if (self.visible) {
            const m = launcherMode.peek();
            if (m === "app") {
              apps.reload();
              setList(apps.fuzzy_query(text.peek()));
              setSelectedIndex(0);
            } else if (m === "cliphist") {
              fetchCliphist().then(items => {
                setClipList(items);
                const val = text.peek();
                const results = items.filter(item => item.content.toLowerCase().includes(val.toLowerCase()));
                setClipFiltered(results);
                setClipSelectedIndex(0);
                loadPreviewFor(0, results);
              });
            }
          }
        });
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
              placeholderText="Search..."
              text={text}
              onActivate={() => {
                if (launcherMode.peek() === "app") {
                  launchSelected();
                } else {
                  const currentList = clipFiltered.peek();
                  const index = clipSelectedIndex.peek();
                  if (currentList[index]) {
                    onHide();
                    execAsync(`bash -c "cliphist decode ${currentList[index].id} | wl-copy"`).catch((e) => {
                      console.error(e);
                    });
                  }
                }
              }}
              $={(self) => {
                self.connect("changed", () => setText(self.text));
                entryRef = self;
                const keyController = new Gtk.EventControllerKey();
                keyController.connect("key-pressed", (controller, keyval) => {
                  const mode = launcherMode.peek();
                  if (mode === "app") {
                    const currentList = list.peek();
                    const index = selectedIndex.peek();
                    if (currentList.length === 0) return false;
                    if (keyval === Gdk.KEY_Down) {
                      setSelectedIndex((index + 1) % currentList.length);
                      return true;
                    }
                    if (keyval === Gdk.KEY_Up) {
                      setSelectedIndex((index - 1 + currentList.length) % currentList.length);
                      return true;
                    }
                  } else {
                    const currentList = clipFiltered.peek();
                    const index = clipSelectedIndex.peek();
                    if (currentList.length === 0) return false;
                    if (keyval === Gdk.KEY_Down) {
                      setClipSelectedIndex((index + 1) % currentList.length);
                      return true;
                    }
                    if (keyval === Gdk.KEY_Up) {
                      setClipSelectedIndex((index - 1 + currentList.length) % currentList.length);
                      return true;
                    }
                  }
                  return false;
                });
                self.add_controller(keyController);
              }}
            />
          </box>
          <With value={launcherMode}>
            {(mode) => (
              mode === "app" ? (
                <ScrollList
                  list={list}
                  selectedIndex={selectedIndex}
                  onHide={onHide}
                />
              ) : (
                <box cssClasses={["cliphist-layout"]}>
                  <CliphistScrollList
                    list={clipFiltered}
                    selectedIndex={clipSelectedIndex}
                    onHide={onHide}
                  />
                  <box cssClasses={["preview-panel"]} hexpand>
                    <With value={previewImage}>
                      {(img) => img ? (
                        <box
                          halign={Gtk.Align.FILL}
                          valign={Gtk.Align.FILL}
                          hexpand
                          vexpand
                          $={(self) => {
                            const provider = new Gtk.CssProvider();
                            provider.load_from_string(`* { background-image: url("file://${img}"); background-size: contain; background-repeat: no-repeat; background-position: center; }`);
                            self.get_style_context().add_provider(provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
                          }}
                        />
                      ) : (
                        <box hexpand vexpand>
                          <With value={previewText}>
                            {(txt) => txt ? (
                              <scrolledwindow hexpand vexpand>
                                <label
                                  label={txt}
                                  halign={Gtk.Align.START}
                                  valign={Gtk.Align.START}
                                  wrap={true}
                                  wrapMode={Pango.WrapMode.WORD_CHAR}
                                  xalign={0}
                                  yalign={0}
                                  selectable={true}
                                  cssClasses={["preview-text"]}
                                />
                              </scrolledwindow>
                            ) : (
                              <label label="Loading..." halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER} hexpand vexpand />
                            )}
                          </With>
                        </box>
                      )}
                    </With>
                  </box>
                </box>
              )
            )}
          </With>
        </box>
      </overlay>
    </window>
  );
}

export function toggleLauncher(mode: "app" | "cliphist" = "app") {
  setLauncherMode(mode);
  const hyprland = Hyprland.get_default()
  const monitor: Hyprland.Monitor | undefined = hyprland.get_monitors().find((monitor) => monitor.focused);
  if (monitor) {
    app.toggle_window(`launcher-${monitor.id}`);
  }
}
