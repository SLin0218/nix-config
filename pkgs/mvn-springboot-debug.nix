{ pkgs }:

# 高版本 JDK 默认开启了严格的模块封装（Strong Encapsulation），不再允许外部库（如 HotswapAgent）通过反射随意读取 java.base 模块下的 JVM 内部私有属性，因此抛出了 InaccessibleObjectException。
# 告诉 JVM 放开对 sun.nio.ch 的反射限制。 --add-opens=java.base/sun.nio.ch=ALL-UNNAMED

pkgs.writeShellScriptBin "mvn-springboot-debug" ''
  HOTSWAP_DIR="$HOME/.config/emacs/.cache"
  HOTSWAP_JAR="$HOTSWAP_DIR/hotswap-agent.jar"

  if [ ! -f "$HOTSWAP_JAR" ]; then
    echo "HotswapAgent JAR not found at $HOTSWAP_JAR. Downloading..."
    mkdir -p "$HOTSWAP_DIR"
    ${pkgs.curl}/bin/curl -L -o "$HOTSWAP_JAR" "https://github.com/HotswapProjects/HotswapAgent/releases/download/RELEASE-2.0.3/hotswap-agent-2.0.3.jar"
    if [ $? -ne 0 ]; then
      echo "Error: Failed to download HotswapAgent JAR." >&2
      exit 1
    fi
    echo "HotswapAgent JAR downloaded successfully."
  fi

  MVN_CMD="mvn"
  if [ -f "./mvnw" ]; then
    MVN_CMD="./mvnw"
  fi

  PL_ARG=""
  if [ -n "$1" ]; then
    PL_ARG="-pl $1"
  fi

  exec $MVN_CMD spring-boot:run $PL_ARG -Dspring-boot.run.jvmArguments=" \
    -XX:+AllowEnhancedClassRedefinition \
    -javaagent:$HOTSWAP_JAR \
    -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005 \
    -Xms2g -Xmx2g -XX:MetaspaceSize=256m -XX:MaxMetaspaceSize=512m \
    -XX:ReservedCodeCacheSize=512m -XX:+UseCodeCacheFlushing \
    -XX:+UseG1GC \
    --add-opens=java.base/sun.nio.ch=ALL-UNNAMED \
    --add-opens java.base/java.lang=ALL-UNNAMED \
    --add-opens java.desktop/java.beans=ALL-UNNAMED \
    --add-opens java.base/java.lang.invoke=ALL-UNNAMED \
    --add-opens java.base/java.io=ALL-UNNAMED \
    --add-opens java.base/java.util=ALL-UNNAMED \
    --add-opens java.base/java.util.concurrent=ALL-UNNAMED"
''
