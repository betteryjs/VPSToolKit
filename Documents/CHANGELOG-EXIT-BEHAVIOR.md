# 退出行为优化更新日志

## 版本 2.0.1 - 2024

### 修改内容

优化了子脚本的退出行为，提升用户体验。现在当用户在子脚本中选择"退出"选项时，不会直接终止整个程序，而是返回到二级菜单。

### 技术细节

**修改的文件：**
1. `scripts/proxy/anytls.sh` - 选项 0
2. `scripts/proxy/ss.sh` - 选项 00
3. `scripts/proxy/snell4.sh` - 选项 0
4. `scripts/proxy/snell5.sh` - 选项 0
5. `scripts/proxy/trojan.sh` - 选项 0
6. `scripts/system/bbr.sh` - 选项 99

**修改内容：**
- 将主菜单中的 `exit 0` 或 `exit 1` 改为 `return`
- 这样当用户选择退出时，控制权会返回到 `vtk-interactive.sh`

### 用户体验改进

**修改前：**
```
[子脚本菜单]
选择 0: 退出脚本
→ 程序直接终止
```

**修改后：**
```
[子脚本菜单]
选择 0: 退出脚本
→ 返回二级菜单
   1. 返回主菜单
   0. 退出脚本
→ 用户可以选择返回主菜单继续操作，或真正退出程序
```

### 实现原理

```bash
# 旧代码
case "$num" in
    0)
    exit 0  # 直接终止程序
    ;;
esac

# 新代码
case "$num" in
    0)
    return  # 返回到调用者（vtk-interactive.sh）
    ;;
esac
```

vtk-interactive.sh 中的二级菜单逻辑：
```bash
# 执行脚本
bash "$action"

# 二级菜单
echo ""
echo "========================================"
echo -e " ${Green_font}1.${Reset} 返回主菜单"
echo -e " ${Green_font}0.${Reset} 退出脚本"
echo "========================================"
read -e -p " 请选择 [0-1]：" choice

case "$choice" in
    1|"")
        # 返回主菜单
        ;;
    0)
        # 真正退出
        exit 0
        ;;
esac
```

### 影响范围

所有通过 vtk-interactive.sh 交互式菜单调用的脚本都将享受这个改进。如果用户直接运行子脚本（不通过 m.sh），退出行为保持不变。

### 向后兼容性

✅ 完全向后兼容
- 直接调用子脚本的用户不受影响
- `return` 在脚本末尾执行时等同于脚本正常结束
- 不影响任何功能性代码

### 测试建议

1. 运行 `bash m.sh` 或 `bash vtk-interactive.sh`
2. 进入任意子脚本菜单（如 Shadowsocks、Trojan 等）
3. 选择退出选项（通常是 0 或 00 或 99）
4. 验证是否显示二级菜单
5. 测试返回主菜单和退出脚本两个选项

### 相关文件

- [vtk-interactive.sh](vtk-interactive.sh) - 交互式菜单主程序
- [m.sh](m.sh) - 统一入口脚本
- [scripts/](scripts/) - 所有子脚本目录
