-- Violence District | Clean ESP Menu v5
-- القائمة مخفية عند التشغيل. الزر الافتراضي لفتحها: Delete (تقدر تغيّره من Settings)

local G = {}   -- جدول مشترك: يخفف عدد المتغيرات المحلية (حد Luau = 200)
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

-- تنظيف التشغيل السابق
if _G.CleanESP_Cleanup then pcall(_G.CleanESP_Cleanup) end
for _, n in ipairs({"CleanESPMenu", "CleanESPOverlay"}) do
    local old = CoreGui:FindFirstChild(n)
    if old then old:Destroy() end
end

local connections = {}
local function track(conn)
    table.insert(connections, conn)
    return conn
end

local hasDrawing = false
pcall(function() hasDrawing = (Drawing ~= nil and Drawing.new ~= nil) end)

---------------------------------------------------------------------
-- الإعدادات الأساسية
---------------------------------------------------------------------
_G.MenuSettings = {
    HoverMode = true,
    MenuTextSize = 14,
    ContentTextSize = 14,
    PlayerRange = 600   -- بالمتر
}

for _, prefix in ipairs({"Survivor", "Killer"}) do
    _G[prefix .. "_Enabled"] = false
    _G[prefix .. "_Name"] = false
    _G[prefix .. "_Distance"] = false
    _G[prefix .. "_Highlight"] = false
    _G[prefix .. "_Skeleton"] = false
end

_G.Survivor_Color = Color3.fromRGB(255, 255, 255)
_G.Survivor_DistanceColor = Color3.fromRGB(255, 255, 255)
_G.Survivor_HighlightColor = Color3.fromRGB(50, 150, 255)
_G.Survivor_SkeletonColor = Color3.fromRGB(255, 255, 255)

_G.Killer_Color = Color3.fromRGB(255, 50, 50)
_G.Killer_DistanceColor = Color3.fromRGB(255, 255, 255)
_G.Killer_HighlightColor = Color3.fromRGB(255, 50, 50)
_G.Killer_SkeletonColor = Color3.fromRGB(255, 50, 50)

local C = {
    Bg = Color3.fromRGB(18, 18, 20),
    Side = Color3.fromRGB(24, 24, 28),
    Active = Color3.fromRGB(35, 35, 42),
    Card = Color3.fromRGB(26, 26, 32),
    Row = Color3.fromRGB(32, 32, 40),
    RowHover = Color3.fromRGB(40, 40, 50),
    Off = Color3.fromRGB(45, 45, 55),
    BoxOff = Color3.fromRGB(30, 30, 38),
    BoxBorder = Color3.fromRGB(75, 75, 92),
    Accent = Color3.fromRGB(115, 60, 240),
    AccentHover = Color3.fromRGB(140, 90, 255),
    Text = Color3.fromRGB(240, 240, 250),
    White = Color3.fromRGB(255, 255, 255),
    Dim = Color3.fromRGB(140, 140, 150),
    DimHover = Color3.fromRGB(195, 195, 205),
    PillOff = Color3.fromRGB(30, 27, 42),
    PillOn = Color3.fromRGB(44, 34, 78),
    Danger = Color3.fromRGB(255, 90, 90)
}

local paletteColors = {
    Color3.fromRGB(255, 255, 255),
    Color3.fromRGB(255, 50, 50),
    Color3.fromRGB(50, 255, 50),
    Color3.fromRGB(50, 150, 255),
    Color3.fromRGB(255, 220, 50)
}

-- إعدادات النصوص داخل اللعبة (مكانها وشكلها)
G.TextCfg = {
    pname = {pos = "above", ox = 0, oy = -14, size = 14, bold = true, spaced = false, outline = 75, opacity = 100},
    pdist = {pos = "above", ox = 0, oy = 0, size = 11, bold = true, spaced = false, outline = 75, opacity = 100, format = 1},
    oname = {pos = "center", ox = 0, oy = -8, size = 13, bold = true, spaced = false, outline = 70, opacity = 100},
    odist = {pos = "center", ox = 0, oy = 8, size = 11, bold = true, spaced = false, outline = 70, opacity = 100, format = 1}
}
G.TextOrder = {"pname", "pdist", "oname", "odist"}
G.TextDefaults = {}
for k, v in pairs(G.TextCfg) do
    local copy = {}
    for kk, vv in pairs(v) do copy[kk] = vv end
    G.TextDefaults[k] = copy
end
G.DistFormats = {"[%d m]", "(%d m)", "%d m", "%dm", "%d"}

-- إعدادات الإضاءة والأجواء
G.LightCfg = {
    enabled = false, brightness = 2, exposure = 0, ambient = 110, time = 14,
    fogAmount = 0, shadows = true, effects = true, snow = false, snowAmount = 50,
    tint = Color3.fromRGB(255, 255, 255), fogColor = Color3.fromRGB(190, 190, 195)
}

-- إعدادات مظهر القائمة
G.AppCfg = {scale = 100, bgOpacity = 100, bgColorIndex = 1, imageId = "", imageOpacity = 35}

G.CameraCfg = {
    enabled = false, fov = 70, firstPerson = false,
    zoomEnabled = false, zoomMin = 0.5, zoomMax = 128,
    showFps = false, fpsSize = 14
}
G.BgColors = {
    Color3.fromRGB(18, 18, 20), Color3.fromRGB(10, 10, 12), Color3.fromRGB(26, 18, 44),
    Color3.fromRGB(16, 26, 44), Color3.fromRGB(0, 0, 0)
}

local menuKey = Enum.KeyCode.Delete
G.menuVisible = false

---------------------------------------------------------------------
-- الخطوط
---------------------------------------------------------------------
local ScreenGui          -- يعرّف لاحقاً
G.fontObjects = {}
G.currentFace = nil
G.styleVersion = 0
G.boldCache = {}

function G.bumpStyle() G.styleVersion += 1 end

local function make(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    if class == "TextLabel" or class == "TextButton" or class == "TextBox" then
        if class ~= "TextBox" and props.TextTruncate == nil then
            o.TextTruncate = Enum.TextTruncate.AtEnd
        end
        if G.currentFace then pcall(function() o.FontFace = G.currentFace end) end
        if parent and ScreenGui and parent:IsDescendantOf(ScreenGui) then
            G.fontObjects[#G.fontObjects + 1] = o
        end
    end
    o.Parent = parent
    return o
end

local function corner(obj, r)
    return make("UICorner", {CornerRadius = UDim.new(0, r)}, obj)
end

local function tween(obj, t, props, style, dir)
    local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

-- نص ينمو ويلتف على أكثر من سطر بدل ما ينقطع، وحجمه يتحكم فيه السلايدر
function G.autoLabel(label, group, size)
    label.TextWrapped = true
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.TextSize = size
    label.TextTruncate = Enum.TextTruncate.None
    if group then table.insert(group, label) end
end

-- نص يتقلّص تلقائياً داخل مساحة ثابتة (للأزرار الصغيرة)
function G.fitLabel(label, group, size)
    label.TextScaled = false
    label.TextWrapped = false
    label.TextTruncate = Enum.TextTruncate.None
    label.AutomaticSize = Enum.AutomaticSize.XY
    label.TextSize = size
    if group then table.insert(group, label) end
end

function G.applyTextSize(label, size)
    local c = label:FindFirstChildOfClass("UITextSizeConstraint")
    if c then c.MaxTextSize = size else label.TextSize = size end
end

G.FontList = {}
for _, f in ipairs({
    {"Gotham", "GothamBold"},
    {"Source Sans", "SourceSansBold"},
    {"Arial", "ArialBold"},
    {"Ubuntu", "Ubuntu"},
    {"Roboto", "Roboto"},
    {"Nunito", "Nunito"}
}) do
    pcall(function()
        table.insert(G.FontList, {id = f[1], face = Font.fromEnum(Enum.Font[f[2]])})
    end)
end
if #G.FontList == 0 then G.FontList[1] = {id = "Default", face = nil} end

G.fontById = {}
for _, f in ipairs(G.FontList) do G.fontById[f.id] = f end

G.currentFontId = G.FontList[1].id
local fontChosenByUser = false

function G.applyFontId(id)
    local f = G.fontById[id]
    if not f then return end
    G.currentFontId = id
    G.currentFace = f.face
    G.boldCache = {}
    G.bumpStyle()
    if not G.currentFace then return end
    local alive = {}
    for _, o in ipairs(G.fontObjects) do
        if o and o.Parent then
            pcall(function() o.FontFace = G.currentFace end)
            alive[#alive + 1] = o
        end
    end
    G.fontObjects = alive
end

-- خط نصوص اللعبة (عريض أو عادي) من نفس عائلة الخط المختار
function G.gameFace(bold)
    if not G.currentFace then return nil end
    local key = G.currentFontId .. (bold and "|B" or "|R")
    if G.boldCache[key] == nil then
        local ok, f = pcall(function()
            return Font.new(G.currentFace.Family, bold and Enum.FontWeight.Bold or Enum.FontWeight.Regular, G.currentFace.Style)
        end)
        G.boldCache[key] = (ok and f) or false
    end
    return G.boldCache[key] or G.currentFace
end

function G.defaultFontFor(lang)
    if lang == "ar" and G.fontById["Source Sans"] then return "Source Sans" end
    return G.FontList[1].id
end

---------------------------------------------------------------------
-- اللغات
---------------------------------------------------------------------
local Lang = {}

Lang.en = {
    ["nav.player"] = "Player ESP", ["nav.survivor"] = "Survivor", ["nav.killer"] = "Killer",
    ["nav.objects"] = "Objects ESP", ["nav.settings"] = "Settings",
    ["opt.enabled"] = "Enabled", ["opt.name"] = "Name", ["opt.distance"] = "Distance",
    ["opt.highlight"] = "Highlight", ["opt.skeleton"] = "Skeleton", ["opt.skeletonNA"] = "Skeleton (unsupported)",
    ["hint.pick"] = "Press > to pick a color", ["hint.editing"] = "Editing %s color",
    ["picker.title"] = "Custom color · %s",
    ["tab.general"] = "General", ["tab.appearance"] = "Appearance", ["tab.text"] = "ESP Text", ["tab.world"] = "World",
    ["set.prefs"] = "Menu Preferences", ["set.hover"] = "Global Hover Mode",
    ["set.menuSize"] = "Menu Text Size", ["set.contentSize"] = "Content Text Size", ["set.nameSize"] = "Name Text Size",
    ["set.menuKey"] = "Menu key", ["set.keyListening"] = "Press a key…",
    ["set.profiles"] = "Profiles", ["set.user"] = "Signed in as", ["set.autosave"] = "Auto-save settings",
    ["set.profileName"] = "Profile name", ["set.save"] = "Save", ["set.load"] = "Load",
    ["set.noProfiles"] = "No saved profiles yet", ["set.language"] = "Language", ["set.font"] = "Font",
    ["set.saved"] = "Saved: %s", ["set.loaded"] = "Loaded: %s", ["set.deleted"] = "Deleted: %s",
    ["set.needName"] = "Type a profile name first",
    ["set.noFiles"] = "No file access: saved for this session only",
    ["set.autosaved"] = "Auto-saved",
    ["set.range"] = "ESP Range", ["set.rangePlayers"] = "Players range (m)",
    ["notify.sub"] = "Script is running. Press the key to open the menu.",
    ["app.title"] = "Menu appearance", ["app.scale"] = "Menu size (%)", ["app.bgOpacity"] = "Background opacity (%)",
    ["app.bgColor"] = "Background color", ["app.bgImage"] = "Background image ID", ["app.imgOpacity"] = "Image opacity (%)",
    ["app.reset"] = "Reset appearance",
    ["txt.title"] = "Text placement", ["txt.pname"] = "Player name", ["txt.pdist"] = "Player distance",
    ["txt.oname"] = "Object name", ["txt.odist"] = "Object distance", ["txt.preview"] = "Preview",
    ["txt.controls"] = "Edit selected text", ["txt.pos"] = "Position", ["txt.above"] = "Above",
    ["txt.center"] = "Center", ["txt.below"] = "Below", ["txt.ox"] = "Horizontal offset",
    ["txt.oy"] = "Vertical offset", ["txt.size"] = "Text size", ["txt.bold"] = "Bold",
    ["txt.spaced"] = "Spaced letters", ["txt.outline"] = "Outline", ["txt.opacity"] = "Opacity (%)",
    ["txt.format"] = "Distance format", ["txt.reset"] = "Reset this text",
    ["world.title"] = "Lighting", ["world.enable"] = "Custom lighting", ["world.presets"] = "Presets",
    ["world.p.fullbright"] = "Fullbright", ["world.p.day"] = "Day", ["world.p.sunset"] = "Sunset",
    ["world.p.night"] = "Bright night", ["world.p.fog"] = "Fog", ["world.p.winter"] = "Winter",
    ["world.restore"] = "Restore game lighting", ["world.brightness"] = "Brightness",
    ["world.exposure"] = "Exposure", ["world.ambient"] = "Ambient light", ["world.time"] = "Time of day",
    ["world.fog"] = "Fog distance", ["world.options"] = "Options", ["world.shadows"] = "Shadows",
    ["world.effects"] = "Post effects", ["world.snow"] = "Snow", ["world.snowAmount"] = "Snow amount",
    ["obj.env"] = "Environment", ["obj.special"] = "Special", ["obj.display"] = "Display",
    ["obj.showDistance"] = "Show distance", ["obj.range"] = "Objects range (m)", ["obj.maxLabels"] = "Max labels",
    ["obj.Generator"] = "Generator", ["obj.Pallet"] = "Pallet", ["obj.Window"] = "Window",
    ["obj.Totem"] = "Totem", ["obj.Hatch"] = "Hatch", ["obj.EscapeDoor"] = "Escape Door",
    ["obj.Breakable"] = "Breakable", ["obj.Locker"] = "Locker", ["obj.MeatHook"] = "Meat Hook",
    ["obj.BreakableWall"] = "Breakable Wall", ["obj.Item"] = "Item", ["obj.Traps"] = "Traps",
    ["obj.CenobiteBox"] = "Cenobite Box", ["obj.ConjoinedTwin"] = "Conjoined Twin", ["obj.Zombie"] = "Zombie",
    ["obj.Drone"] = "Drone", ["obj.Guard"] = "Guard", ["obj.Dog"] = "Dog"
}

Lang.ar = {
    ["nav.player"] = "كشف اللاعبين", ["nav.survivor"] = "الناجي", ["nav.killer"] = "القاتل",
    ["nav.objects"] = "كشف الأغراض", ["nav.settings"] = "الإعدادات",
    ["opt.enabled"] = "مفعّل", ["opt.name"] = "الاسم", ["opt.distance"] = "المسافة",
    ["opt.highlight"] = "التظليل", ["opt.skeleton"] = "الهيكل العظمي", ["opt.skeletonNA"] = "الهيكل العظمي (غير مدعوم)",
    ["hint.pick"] = "اضغط على السهم لاختيار لون", ["hint.editing"] = "تعديل لون %s",
    ["picker.title"] = "لون مخصص · %s",
    ["tab.general"] = "عام", ["tab.appearance"] = "المظهر", ["tab.text"] = "نصوص الكشف", ["tab.world"] = "العالم",
    ["set.prefs"] = "تفضيلات القائمة", ["set.hover"] = "وضع التمرير العام",
    ["set.menuSize"] = "حجم خط القائمة", ["set.contentSize"] = "حجم خط المحتوى", ["set.nameSize"] = "حجم خط الاسم",
    ["set.menuKey"] = "زر القائمة", ["set.keyListening"] = "اضغط أي زر…",
    ["set.profiles"] = "الإعدادات المحفوظة", ["set.user"] = "مسجّل الدخول باسم", ["set.autosave"] = "حفظ تلقائي للإعدادات",
    ["set.profileName"] = "اسم الإعداد", ["set.save"] = "حفظ", ["set.load"] = "تحميل",
    ["set.noProfiles"] = "لا توجد إعدادات محفوظة بعد", ["set.language"] = "اللغة", ["set.font"] = "الخط",
    ["set.saved"] = "تم الحفظ: %s", ["set.loaded"] = "تم التحميل: %s", ["set.deleted"] = "تم الحذف: %s",
    ["set.needName"] = "اكتب اسماً للإعداد أولاً",
    ["set.noFiles"] = "لا يوجد دعم للملفات: الحفظ لهذه الجلسة فقط",
    ["set.autosaved"] = "تم الحفظ تلقائياً",
    ["set.range"] = "نطاق الكشف", ["set.rangePlayers"] = "نطاق اللاعبين (م)",
    ["notify.sub"] = "السكربت يعمل. اضغط الزر لفتح القائمة.",
    ["app.title"] = "مظهر القائمة", ["app.scale"] = "حجم القائمة (%)", ["app.bgOpacity"] = "وضوح الخلفية (%)",
    ["app.bgColor"] = "لون الخلفية", ["app.bgImage"] = "رقم صورة الخلفية", ["app.imgOpacity"] = "وضوح الصورة (%)",
    ["app.reset"] = "إعادة المظهر الافتراضي",
    ["txt.title"] = "مكان النصوص", ["txt.pname"] = "اسم اللاعب", ["txt.pdist"] = "مسافة اللاعب",
    ["txt.oname"] = "اسم الغرض", ["txt.odist"] = "مسافة الغرض", ["txt.preview"] = "معاينة",
    ["txt.controls"] = "تعديل النص المحدد", ["txt.pos"] = "الموضع", ["txt.above"] = "فوق",
    ["txt.center"] = "وسط", ["txt.below"] = "تحت", ["txt.ox"] = "إزاحة أفقية",
    ["txt.oy"] = "إزاحة عمودية", ["txt.size"] = "حجم النص", ["txt.bold"] = "عريض",
    ["txt.spaced"] = "حروف متباعدة", ["txt.outline"] = "الحدود", ["txt.opacity"] = "الوضوح (%)",
    ["txt.format"] = "شكل المسافة", ["txt.reset"] = "إعادة هذا النص",
    ["world.title"] = "الإضاءة", ["world.enable"] = "إضاءة مخصصة", ["world.presets"] = "إعدادات جاهزة",
    ["world.p.fullbright"] = "إضاءة كاملة", ["world.p.day"] = "نهار", ["world.p.sunset"] = "غروب",
    ["world.p.night"] = "ليل مضيء", ["world.p.fog"] = "ضباب", ["world.p.winter"] = "شتاء",
    ["world.restore"] = "استرجاع إضاءة اللعبة", ["world.brightness"] = "السطوع",
    ["world.exposure"] = "التعريض", ["world.ambient"] = "الإضاءة المحيطة", ["world.time"] = "وقت اليوم",
    ["world.fog"] = "مسافة الضباب", ["world.options"] = "خيارات", ["world.shadows"] = "الظلال",
    ["world.effects"] = "المؤثرات البصرية", ["world.snow"] = "ثلج", ["world.snowAmount"] = "كمية الثلج",
    ["obj.env"] = "البيئة", ["obj.special"] = "خاص", ["obj.display"] = "العرض",
    ["obj.showDistance"] = "إظهار المسافة", ["obj.range"] = "نطاق الأغراض (م)", ["obj.maxLabels"] = "أقصى عدد للعناوين",
    ["obj.Generator"] = "المولّد", ["obj.Pallet"] = "اللوح", ["obj.Window"] = "النافذة",
    ["obj.Totem"] = "الطوطم", ["obj.Hatch"] = "فتحة الهروب", ["obj.EscapeDoor"] = "باب الهروب",
    ["obj.Breakable"] = "قابل للكسر", ["obj.Locker"] = "الخزانة", ["obj.MeatHook"] = "خطاف اللحم",
    ["obj.BreakableWall"] = "جدار قابل للكسر", ["obj.Item"] = "غرض", ["obj.Traps"] = "الفخاخ",
    ["obj.CenobiteBox"] = "صندوق السينوبايت", ["obj.ConjoinedTwin"] = "التوأم الملتصق", ["obj.Zombie"] = "زومبي",
    ["obj.Drone"] = "درون", ["obj.Guard"] = "حارس", ["obj.Dog"] = "كلب"
}

Lang.es = {
    ["nav.player"] = "ESP de jugadores", ["nav.survivor"] = "Superviviente", ["nav.killer"] = "Asesino",
    ["nav.objects"] = "ESP de objetos", ["nav.settings"] = "Ajustes",
    ["opt.enabled"] = "Activado", ["opt.name"] = "Nombre", ["opt.distance"] = "Distancia",
    ["opt.highlight"] = "Resaltado", ["opt.skeleton"] = "Esqueleto", ["opt.skeletonNA"] = "Esqueleto (no compatible)",
    ["hint.pick"] = "Pulsa > para elegir un color", ["hint.editing"] = "Editando color: %s",
    ["picker.title"] = "Color personalizado · %s",
    ["tab.general"] = "General", ["tab.appearance"] = "Apariencia", ["tab.text"] = "Texto ESP", ["tab.world"] = "Mundo",
    ["set.prefs"] = "Preferencias del menú", ["set.hover"] = "Modo hover global",
    ["set.menuSize"] = "Tamaño de texto del menú", ["set.contentSize"] = "Tamaño de texto del contenido", ["set.nameSize"] = "Tamaño de texto del nombre",
    ["set.profiles"] = "Perfiles", ["set.user"] = "Sesión de", ["set.autosave"] = "Guardado automático",
    ["set.profileName"] = "Nombre del perfil", ["set.save"] = "Guardar", ["set.load"] = "Cargar",
    ["set.noProfiles"] = "Aún no hay perfiles guardados", ["set.language"] = "Idioma", ["set.font"] = "Fuente",
    ["set.saved"] = "Guardado: %s", ["set.loaded"] = "Cargado: %s", ["set.deleted"] = "Eliminado: %s",
    ["set.needName"] = "Escribe primero un nombre",
    ["set.noFiles"] = "Sin acceso a archivos: solo esta sesión",
    ["set.autosaved"] = "Guardado automáticamente",
    ["set.range"] = "Alcance ESP", ["set.rangePlayers"] = "Alcance de jugadores (m)",
    ["obj.env"] = "Entorno", ["obj.special"] = "Especial", ["obj.display"] = "Pantalla",
    ["obj.showDistance"] = "Mostrar distancia", ["obj.range"] = "Alcance de objetos (m)", ["obj.maxLabels"] = "Máx. etiquetas"
}

Lang.fr = {
    ["nav.player"] = "ESP joueurs", ["nav.survivor"] = "Survivant", ["nav.killer"] = "Tueur",
    ["nav.objects"] = "ESP objets", ["nav.settings"] = "Paramètres",
    ["opt.enabled"] = "Activé", ["opt.name"] = "Nom", ["opt.distance"] = "Distance",
    ["opt.highlight"] = "Surbrillance", ["opt.skeleton"] = "Squelette", ["opt.skeletonNA"] = "Squelette (non pris en charge)",
    ["hint.pick"] = "Appuie sur > pour choisir une couleur", ["hint.editing"] = "Modification de la couleur : %s",
    ["picker.title"] = "Couleur personnalisée · %s",
    ["tab.general"] = "Général", ["tab.appearance"] = "Apparence", ["tab.text"] = "Texte ESP", ["tab.world"] = "Monde",
    ["set.prefs"] = "Préférences du menu", ["set.hover"] = "Survol global",
    ["set.menuSize"] = "Taille du texte du menu", ["set.contentSize"] = "Taille du texte du contenu", ["set.nameSize"] = "Taille du texte du nom",
    ["set.profiles"] = "Profils", ["set.user"] = "Connecté en tant que", ["set.autosave"] = "Sauvegarde automatique",
    ["set.profileName"] = "Nom du profil", ["set.save"] = "Enregistrer", ["set.load"] = "Charger",
    ["set.noProfiles"] = "Aucun profil enregistré", ["set.language"] = "Langue", ["set.font"] = "Police",
    ["set.saved"] = "Enregistré : %s", ["set.loaded"] = "Chargé : %s", ["set.deleted"] = "Supprimé : %s",
    ["set.needName"] = "Saisis d'abord un nom",
    ["set.noFiles"] = "Pas d'accès aux fichiers : session uniquement",
    ["set.autosaved"] = "Sauvegardé automatiquement",
    ["set.range"] = "Portée ESP", ["set.rangePlayers"] = "Portée joueurs (m)",
    ["obj.env"] = "Environnement", ["obj.special"] = "Spécial", ["obj.display"] = "Affichage",
    ["obj.showDistance"] = "Afficher la distance", ["obj.range"] = "Portée objets (m)", ["obj.maxLabels"] = "Étiquettes max."
}

Lang.tr = {
    ["nav.player"] = "Oyuncu ESP", ["nav.survivor"] = "Hayatta Kalan", ["nav.killer"] = "Katil",
    ["nav.objects"] = "Nesne ESP", ["nav.settings"] = "Ayarlar",
    ["opt.enabled"] = "Etkin", ["opt.name"] = "İsim", ["opt.distance"] = "Mesafe",
    ["opt.highlight"] = "Vurgu", ["opt.skeleton"] = "İskelet", ["opt.skeletonNA"] = "İskelet (desteklenmiyor)",
    ["hint.pick"] = "Renk seçmek için > tuşuna bas", ["hint.editing"] = "%s rengi düzenleniyor",
    ["picker.title"] = "Özel renk · %s",
    ["tab.general"] = "Genel", ["tab.appearance"] = "Görünüm", ["tab.text"] = "ESP Metni", ["tab.world"] = "Dünya",
    ["set.prefs"] = "Menü Tercihleri", ["set.hover"] = "Genel Üzerine Gelme Modu",
    ["set.menuSize"] = "Menü Yazı Boyutu", ["set.contentSize"] = "İçerik Yazı Boyutu", ["set.nameSize"] = "İsim Yazı Boyutu",
    ["set.profiles"] = "Profiller", ["set.user"] = "Oturum", ["set.autosave"] = "Otomatik kaydet",
    ["set.profileName"] = "Profil adı", ["set.save"] = "Kaydet", ["set.load"] = "Yükle",
    ["set.noProfiles"] = "Henüz kayıtlı profil yok", ["set.language"] = "Dil", ["set.font"] = "Yazı tipi",
    ["set.saved"] = "Kaydedildi: %s", ["set.loaded"] = "Yüklendi: %s", ["set.deleted"] = "Silindi: %s",
    ["set.needName"] = "Önce bir ad yaz",
    ["set.noFiles"] = "Dosya erişimi yok: yalnızca bu oturum",
    ["set.autosaved"] = "Otomatik kaydedildi",
    ["set.range"] = "ESP Menzili", ["set.rangePlayers"] = "Oyuncu menzili (m)",
    ["obj.env"] = "Çevre", ["obj.special"] = "Özel", ["obj.display"] = "Görünüm",
    ["obj.showDistance"] = "Mesafeyi göster", ["obj.range"] = "Nesne menzili (m)", ["obj.maxLabels"] = "Maks. etiket"
}

Lang.en["set.fixKey"] = "Camera fix key"
Lang.en["hint.camTitle"] = "Camera stuck?"
Lang.en["hint.camSub"] = "Press the key to restore it."
Lang.en["notify.camFixed"] = "Camera restored"
Lang.ar["set.fixKey"] = "زر إصلاح الكاميرا"
Lang.ar["hint.camTitle"] = "الكاميرا عالقة؟"
Lang.ar["hint.camSub"] = "اضغط الزر لإرجاعها طبيعية."
Lang.ar["notify.camFixed"] = "تم إرجاع الكاميرا"

Lang.en["tab.camera"] = "Camera"
Lang.en["cam.title"] = "Camera & FOV"
Lang.en["cam.enable"] = "Custom camera"
Lang.en["cam.fov"] = "Field of view"
Lang.en["cam.firstPerson"] = "First-person view"
Lang.en["cam.zoomEnable"] = "Custom zoom limits"
Lang.en["cam.zoomMin"] = "Min zoom distance"
Lang.en["cam.zoomMax"] = "Max zoom distance"
Lang.en["cam.reset"] = "Reset to default"
Lang.en["cam.fps"] = "Show FPS / Ping"
Lang.en["cam.fpsSize"] = "FPS text size"
Lang.ar["tab.camera"] = "الكاميرا"
Lang.ar["cam.title"] = "الكاميرا والمنظور"
Lang.ar["cam.enable"] = "كاميرا مخصصة"
Lang.ar["cam.fov"] = "زاوية الرؤية"
Lang.ar["cam.firstPerson"] = "منظور أول شخص"
Lang.ar["cam.zoomEnable"] = "حدود تقريب مخصصة"
Lang.ar["cam.zoomMin"] = "أقل مسافة تقريب"
Lang.ar["cam.zoomMax"] = "أقصى مسافة تقريب"
Lang.ar["cam.reset"] = "إرجاع الافتراضي"
Lang.ar["cam.fps"] = "إظهار FPS / البينق"
Lang.ar["cam.fpsSize"] = "حجم خط FPS"

Lang.en["notify.camFixedSub"] = "Move the mouse to look around. Press the key again to release it."
Lang.en["notify.camReleased"] = "Camera released"
Lang.ar["notify.camFixedSub"] = "حرّك الماوس عشان تلف الكاميرا. اضغط الزر مرة ثانية عشان تطلقها."
Lang.ar["notify.camReleased"] = "تم تحرير الكاميرا"

G.LangList = {
    {id = "en", name = "English"},
    {id = "ar", name = "العربية"},
    {id = "es", name = "Español"},
    {id = "fr", name = "Français"},
    {id = "tr", name = "Türkçe"}
}

G.currentLang = "en"

local function T(key, ...)
    local s = (Lang[G.currentLang] and Lang[G.currentLang][key]) or Lang.en[key] or key
    if select("#", ...) > 0 then
        local ok, r = pcall(string.format, s, ...)
        if ok then return r end
    end
    return s
end

G.binds = {}
G.langListeners = {}

function G.applyBind(b)
    local args = b.args and b.args() or {}
    b.obj[b.prop] = T(b.key, table.unpack(args))
end

local function bind(obj, key, opts)
    opts = opts or {}
    local b = {obj = obj, key = key, args = opts.args, prop = opts.prop or "Text"}
    G.binds[#G.binds + 1] = b
    G.applyBind(b)
    return b
end

function G.applyLanguage(id)
    if not Lang[id] then return end
    G.currentLang = id
    G.bumpStyle()
    local alive = {}
    for _, b in ipairs(G.binds) do
        if b.obj and b.obj.Parent then
            G.applyBind(b)
            alive[#alive + 1] = b
        end
    end
    G.binds = alive
    for _, fn in ipairs(G.langListeners) do pcall(fn) end
end

---------------------------------------------------------------------
-- حالة الحفظ + سجل عناصر التحكم
---------------------------------------------------------------------
G.loading = false
G.dirty = false
G.dirtyAt = 0
local autosaveEnabled = true
G.postApplyHooks = {}   -- تُنفَّذ بعد تحميل أي إعدادات (لتحديث الواجهة)

function G.markDirty()
    if G.loading then return end
    G.dirty = true
    G.dirtyAt = os.clock()
end

G.controls = {}
function G.registerControl(id, get, set)
    G.controls[id] = {get = get, set = set}
end

function G.toColor(v)
    if typeof(v) == "Color3" then return v end
    if type(v) == "table" and v.r and v.g and v.b then
        return Color3.fromRGB(v.r, v.g, v.b)
    end
    return nil
end

function G.snapshot()
    local s = {}
    for id, c in pairs(G.controls) do
        local ok, v = pcall(c.get)
        if ok and v ~= nil then
            if typeof(v) == "Color3" then
                v = {r = math.floor(v.R * 255 + 0.5), g = math.floor(v.G * 255 + 0.5), b = math.floor(v.B * 255 + 0.5)}
            end
            s[id] = v
        end
    end
    return s
end

function G.applySnapshot(s)
    if type(s) ~= "table" then return end
    G.loading = true
    for _, id in ipairs({"Language", "Font"}) do
        if s[id] ~= nil and G.controls[id] then pcall(G.controls[id].set, s[id]) end
    end
    for id, v in pairs(s) do
        if id ~= "Language" and id ~= "Font" and G.controls[id] then
            pcall(G.controls[id].set, v)
        end
    end
    for _, fn in ipairs(G.postApplyHooks) do pcall(fn) end
    G.loading = false
end

---------------------------------------------------------------------
-- التخزين الدائم (ملف خاص بكل حساب حسب الـ UserId)
---------------------------------------------------------------------
G.hasFS = (type(writefile) == "function") and (type(readfile) == "function") and (type(isfile) == "function")
G.STORE_DIR = "CleanESPMenu"
G.userId = tostring(LocalPlayer.UserId)
local storePath = "CleanESPMenu_" .. G.userId .. ".json"

if G.hasFS then
    pcall(function()
        if type(isfolder) == "function" and type(makefolder) == "function" then
            if not isfolder(G.STORE_DIR) then makefolder(G.STORE_DIR) end
            if isfolder(G.STORE_DIR) then storePath = G.STORE_DIR .. "/" .. G.userId .. ".json" end
        end
    end)
end

_G.CleanESP_Memory = _G.CleanESP_Memory or {}

function G.readStore()
    local raw
    if G.hasFS then
        pcall(function()
            if isfile(storePath) then raw = readfile(storePath) end
        end)
    else
        raw = _G.CleanESP_Memory[G.userId]
    end
    if raw then
        local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
        if ok and type(data) == "table" then return data end
    end
    return {}
end

G.StoreData = G.readStore()
G.StoreData.profiles = type(G.StoreData.profiles) == "table" and G.StoreData.profiles or {}
G.StoreData.user = {id = LocalPlayer.UserId, name = LocalPlayer.Name}
if G.StoreData.autosaveEnabled == false then autosaveEnabled = false end

function G.writeStore()
    local ok, raw = pcall(function() return HttpService:JSONEncode(G.StoreData) end)
    if not ok then return false end
    if G.hasFS then
        return (pcall(writefile, storePath, raw))
    end
    _G.CleanESP_Memory[G.userId] = raw
    return true
end

G.onAutoSaved = nil

function G.flushSave()
    if G.dirty and autosaveEnabled then
        G.dirty = false
        G.StoreData.autosave = G.snapshot()
        local ok = G.writeStore()
        if G.onAutoSaved then G.onAutoSaved(ok) end
    end
end

track(RunService.Heartbeat:Connect(function()
    if G.dirty and autosaveEnabled and (os.clock() - G.dirtyAt) > 1.2 then
        G.flushSave()
    end
end))

function G.setLanguage(id)
    if not Lang[id] then return end
    G.applyLanguage(id)
    if not fontChosenByUser then G.applyFontId(G.defaultFontFor(id)) end
    G.markDirty()
end

function G.setFont(id, byUser)
    if not G.fontById[id] then return end
    if byUser then fontChosenByUser = true end
    G.applyFontId(id)
    G.markDirty()
end

G.registerControl("Language", function() return G.currentLang end, function(v)
    if type(v) == "string" and Lang[v] then
        G.applyLanguage(v)
        if not fontChosenByUser then G.applyFontId(G.defaultFontFor(v)) end
    end
end)
G.registerControl("FontChosen", function() return fontChosenByUser end, function(v)
    fontChosenByUser = (v == true)
end)
G.registerControl("Font", function() return G.currentFontId end, function(v)
    if type(v) == "string" and G.fontById[v] then G.applyFontId(v) end
end)

G.menuLabels = {}     -- نصوص تتحكم فيها Menu Text Size
G.contentLabels = {}  -- نصوص تتحكم فيها Content Text Size

function G.groupSize(group)
    return (group == G.menuLabels) and _G.MenuSettings.MenuTextSize or _G.MenuSettings.ContentTextSize
end

-- موقع الماوس بنفس فضاء إحداثيات الواجهة (بدون إزاحة الـ Topbar)
local Mouse = LocalPlayer:GetMouse()
local function getMouse()
    return Vector2.new(Mouse.X, Mouse.Y)
end

---------------------------------------------------------------------
-- النافذة الرئيسية (مخفية عند التشغيل)
---------------------------------------------------------------------
ScreenGui = make("ScreenGui", {
    Name = "CleanESPMenu",
    ResetOnSpawn = false,
    DisplayOrder = 20,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
})
if not pcall(function() ScreenGui.Parent = CoreGui end) then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local MainFrame = make("CanvasGroup", {
    Name = "MainFrame",
    BackgroundColor3 = G.BgColors[1],
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(880, 640),
    Active = true,
    Draggable = true,
    GroupTransparency = 1,
    Visible = false
}, ScreenGui)
corner(MainFrame, 10)
G.MainScale = make("UIScale", {Scale = 0.92}, MainFrame)

-- صورة الخلفية (اختيارية) خلف كل شي
G.BgImage = make("ImageLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
    ScaleType = Enum.ScaleType.Crop,
    Image = "",
    ImageTransparency = 1,
    Visible = false
}, MainFrame)
corner(G.BgImage, 10)

G.Sidebar = make("Frame", {
    BackgroundColor3 = C.Side,
    Size = UDim2.new(0, 280, 1, 0)
}, MainFrame)
corner(G.Sidebar, 10)

G.logoDot = make("Frame", {
    BackgroundColor3 = C.Accent,
    Position = UDim2.new(0, 20, 0, 29),
    Size = UDim2.fromOffset(8, 8)
}, G.Sidebar)
corner(G.logoDot, 4)

make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 36, 0, 18),
    Size = UDim2.new(0, 200, 0, 30),
    Font = Enum.Font.GothamBold,
    Text = "Violence District  ·  v5.3",
    TextColor3 = Color3.fromRGB(240, 240, 255),
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left
}, G.Sidebar)

-- معامل تكبير القائمة الحالي (UIScale + حجم النافذة)
function G.uiScaleFactor()
    local f = MainFrame.AbsoluteSize.X / 880
    if f <= 0 then return 1 end
    return f
end

---------------------------------------------------------------------
-- السحب (سلايدرز + بيكر الألوان) بنظام واحد خفيف
---------------------------------------------------------------------
G.activeDrag = nil

function G.startDrag(fn)
    G.activeDrag = fn
    MainFrame.Draggable = false
    fn(getMouse())
end

track(UserInputService.InputChanged:Connect(function(input)
    if G.activeDrag and input.UserInputType == Enum.UserInputType.MouseMovement then
        G.activeDrag(getMouse())
    end
end))

track(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and G.activeDrag then
        G.activeDrag = nil
        MainFrame.Draggable = true
    end
end))

---------------------------------------------------------------------
-- عناصر الواجهة (كلها تتمدد تلقائياً مع حجم الخط)
---------------------------------------------------------------------
G.orders = setmetatable({}, {__mode = "k"})
local function ord(parent)
    G.orders[parent] = (G.orders[parent] or 0) + 1
    return G.orders[parent]
end

G.pillGrids = {}
function G.pillCell(cols, group)
    return UDim2.new(1 / cols, -(8 * (cols - 1)) / cols, 0, math.max(30, math.floor(G.groupSize(group) * 1.9)))
end
function G.refreshPillGrids()
    for _, g in ipairs(G.pillGrids) do
        if g.grid and g.grid.Parent then
            g.grid.CellSize = G.pillCell(g.cols, g.group)
        end
    end
end

function G.newScroller(parent)
    local scroll = make("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = C.BoxBorder,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y
    }, parent)
    local content = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y
    }, scroll)
    make("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder}, content)
    make("UIPadding", {PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 16)}, content)
    return scroll, content
end

function G.newColumns(content)
    local holder = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = ord(content)
    }, content)
    local function col(x)
        local f = make("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(x, 0),
            Size = UDim2.fromOffset(270, 0),
            AutomaticSize = Enum.AutomaticSize.Y
        }, holder)
        make("UIListLayout", {Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder}, f)
        return f
    end
    return holder, col(0), col(285)
end

function G.newCard(col, titleKey, group)
    local card = make("Frame", {
        BackgroundColor3 = C.Card,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = ord(col)
    }, col)
    corner(card, 8)
    make("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, card)
    make("UIPadding", {
        PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)
    }, card)
    if titleKey then
        local t = make("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 28),
            Font = Enum.Font.GothamBold,
            Text = "",
            TextColor3 = Color3.fromRGB(250, 250, 255),
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = ord(card)
        }, card)
        bind(t, titleKey)
        G.autoLabel(t, group, G.groupSize(group))
    end
    return card
end

-- مربع تحديد (علامة الصح مرسومة بإطارات فما تتأثر بالخط)
function G.createToggle(parent, labelKey, default, group, callback, id, rightPad)
    local btn = make("TextButton", {
        BackgroundColor3 = C.RowHover,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 34),
        AutomaticSize = Enum.AutomaticSize.Y,
        AutoButtonColor = false,
        Text = "",
        LayoutOrder = ord(parent)
    }, parent)
    corner(btn, 6)

    local box = make("Frame", {
        BackgroundColor3 = default and C.Accent or C.BoxOff,
        Position = UDim2.fromOffset(8, 9),
        Size = UDim2.fromOffset(16, 16)
    }, btn)
    corner(box, 4)
    local stroke = make("UIStroke", {
        Color = default and C.Accent or C.BoxBorder,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, box)
    local boxScale = make("UIScale", {}, box)

    local arm1 = make("Frame", {
        BackgroundColor3 = C.White, BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(5, 10),
        Size = UDim2.fromOffset(5, 2), Rotation = 45,
        BackgroundTransparency = default and 0 or 1
    }, box)
    corner(arm1, 1)
    local arm2 = make("Frame", {
        BackgroundColor3 = C.White, BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(9.5, 8),
        Size = UDim2.fromOffset(10, 2), Rotation = -49,
        BackgroundTransparency = default and 0 or 1
    }, box)
    corner(arm2, 1)

    local lbl = make("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(34, 0),
        Size = UDim2.new(1, -(34 + (rightPad or 10)), 0, 34),
        Font = Enum.Font.GothamBold,
        Text = "",
        TextColor3 = Color3.fromRGB(235, 235, 245),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center
    }, btn)
    bind(lbl, labelKey)
    G.autoLabel(lbl, group, G.groupSize(group))

    btn.MouseEnter:Connect(function() tween(btn, 0.15, {BackgroundTransparency = 0.45}) end)
    btn.MouseLeave:Connect(function()
        tween(btn, 0.15, {BackgroundTransparency = 1})
        tween(boxScale, 0.1, {Scale = 1})
    end)
    btn.MouseButton1Down:Connect(function() tween(boxScale, 0.08, {Scale = 0.82}) end)
    btn.MouseButton1Up:Connect(function() tween(boxScale, 0.15, {Scale = 1}, Enum.EasingStyle.Back) end)

    local state = default
    local function setState(v, silent)
        if state == v then return end
        state = v
        tween(box, 0.18, {BackgroundColor3 = v and C.Accent or C.BoxOff})
        tween(stroke, 0.18, {Color = v and C.Accent or C.BoxBorder})
        tween(arm1, 0.18, {BackgroundTransparency = v and 0 or 1})
        tween(arm2, 0.18, {BackgroundTransparency = v and 0 or 1})
        if not silent then
            if callback then callback(v) end
            G.markDirty()
        end
    end
    btn.MouseButton1Click:Connect(function() setState(not state) end)

    local api = {set = function(v, silent) setState(v == true, silent) end, get = function() return state end}
    if id then
        G.registerControl(id, function() return state end, function(v) setState(v == true) end)
    end
    return btn, lbl, api
end

-- سلايدر: العنوان والقيمة بنفس حجم خط المجموعة
function G.createSlider(parent, labelKey, min, max, default, onChange, id, group, fmt)
    group = group or G.contentLabels
    fmt = fmt or tostring
    local s0 = (default - min) / (max - min)

    local row = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = ord(parent)
    }, parent)
    make("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}, row)

    local top = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 22),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 1
    }, row)

    local lbl = make("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(6, 0),
        Size = UDim2.new(1, -70, 0, 22),
        Font = Enum.Font.GothamBold,
        Text = "",
        TextColor3 = Color3.fromRGB(240, 240, 255),
        TextXAlignment = Enum.TextXAlignment.Left
    }, top)
    bind(lbl, labelKey)
    G.autoLabel(lbl, group, G.groupSize(group))

    local valLbl = make("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -4, 0, 0),
        Size = UDim2.fromOffset(0, 22),
        AutomaticSize = Enum.AutomaticSize.X,
        Font = Enum.Font.GothamBold,
        Text = fmt(default),
        TextColor3 = C.Dim,
        TextWrapped = false,
        TextTruncate = Enum.TextTruncate.None,
        TextSize = G.groupSize(group)
    }, top)
    table.insert(group, valLbl)

    local holder = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        LayoutOrder = 2
    }, row)

    local bar = make("Frame", {
        BackgroundColor3 = C.Off,
        Position = UDim2.new(0, 6, 0.5, -2),
        Size = UDim2.new(1, -12, 0, 4)
    }, holder)
    corner(bar, 2)

    local fill = make("Frame", {
        BackgroundColor3 = Color3.fromRGB(140, 100, 255),
        Size = UDim2.new(s0, 0, 1, 0)
    }, bar)
    corner(fill, 2)

    local knob = make("Frame", {
        BackgroundColor3 = C.White,
        Position = UDim2.new(s0, -6, 0.5, -6),
        Size = UDim2.fromOffset(12, 12)
    }, bar)
    corner(knob, 6)
    local knobScale = make("UIScale", {}, knob)

    local hit = make("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = ""
    }, holder)

    local value = default
    local function render(sc)
        fill.Size = UDim2.new(sc, 0, 1, 0)
        knob.Position = UDim2.new(sc, -6, 0.5, -6)
    end

    hit.MouseEnter:Connect(function() tween(knobScale, 0.12, {Scale = 1.25}) end)
    hit.MouseLeave:Connect(function()
        if G.activeDrag == nil then tween(knobScale, 0.12, {Scale = 1}) end
    end)

    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            G.startDrag(function(pos)
                local w = bar.AbsoluteSize.X
                if w <= 0 then return end
                local sc = math.clamp((pos.X - bar.AbsolutePosition.X) / w, 0, 1)
                render(sc)
                local v = math.floor(min + (max - min) * sc + 0.5)
                if v ~= value then
                    value = v
                    valLbl.Text = fmt(v)
                    onChange(v)
                    G.markDirty()
                end
            end)
        end
    end)

    -- silent = تحديث الشكل بدون تشغيل onChange
    local function setValue(v, silent)
        if type(v) ~= "number" then return end
        v = math.clamp(math.floor(v + 0.5), min, max)
        value = v
        valLbl.Text = fmt(v)
        render((v - min) / (max - min))
        if not silent then onChange(v) end
    end

    if id then
        G.registerControl(id, function() return value end, function(v) setValue(v, false) end)
    end
    return {set = setValue, get = function() return value end, row = row}
end

-- أزرار اختيار: تتوزع وتنزل لسطر جديد لحالها، وتكبر مع حجم الخط
function G.createPills(parent, items, getSelected, onSelect, group, cols)
    group = group or G.contentLabels
    cols = cols or 2
    local holder = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = ord(parent)
    }, parent)

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    local flow = pcall(function() layout.Wraps = true end)
    local grid = nil
    if flow then
        layout.Parent = holder
    else
        layout:Destroy()
        grid = make("UIGridLayout", {
            CellSize = G.pillCell(cols, group),
            CellPadding = UDim2.fromOffset(8, 6),
            SortOrder = Enum.SortOrder.LayoutOrder
        }, holder)
        G.pillGrids[#G.pillGrids + 1] = {grid = grid, group = group, cols = cols}
    end

    local pills = {}
    local function refreshAll()
        local sel = getSelected()
        for itemId, p in pairs(pills) do
            local on = (itemId == sel)
            tween(p, 0.18, {BackgroundColor3 = on and C.Accent or C.Row, TextColor3 = on and C.White or C.Dim})
        end
    end

    for i, it in ipairs(items) do
        local b = make("TextButton", {
            BackgroundColor3 = C.Row,
            AutoButtonColor = false,
            Font = Enum.Font.GothamBold,
            Text = it.text or "",
            TextColor3 = C.Dim,
            Size = UDim2.fromOffset(0, 30),
            LayoutOrder = i
        }, holder)
        corner(b, 6)
        if it.key then bind(b, it.key) end
        G.fitLabel(b, group, math.max(it.size or 13, G.groupSize(group)))
        if flow then
            make("UIPadding", {
                PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
                PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6)
            }, b)
        else
            b.AutomaticSize = Enum.AutomaticSize.None
        end
        pills[it.id] = b

        b.MouseEnter:Connect(function()
            if getSelected() ~= it.id then tween(b, 0.12, {BackgroundColor3 = C.RowHover, TextColor3 = C.Text}) end
        end)
        b.MouseLeave:Connect(function()
            if getSelected() ~= it.id then tween(b, 0.12, {BackgroundColor3 = C.Row, TextColor3 = C.Dim}) end
        end)
        b.MouseButton1Click:Connect(function()
            onSelect(it.id)
            refreshAll()
        end)
    end

    refreshAll()
    return refreshAll
end

-- زر عادي
function G.createButton(parent, labelKey, group, callback, danger)
    local b = make("TextButton", {
        BackgroundColor3 = danger and Color3.fromRGB(70, 30, 36) or C.Accent,
        AutoButtonColor = false,
        Size = UDim2.new(1, 0, 0, 32),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Enum.Font.GothamBold,
        Text = "",
        TextColor3 = C.White,
        LayoutOrder = ord(parent)
    }, parent)
    corner(b, 6)
    make("UIPadding", {PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6)}, b)
    bind(b, labelKey)
    G.autoLabel(b, group, G.groupSize(group))
    local base = b.BackgroundColor3
    b.MouseEnter:Connect(function()
        tween(b, 0.12, {BackgroundColor3 = danger and Color3.fromRGB(95, 40, 48) or C.AccentHover})
    end)
    b.MouseLeave:Connect(function() tween(b, 0.12, {BackgroundColor3 = base}) end)
    b.MouseButton1Click:Connect(callback)
    return b
end

-- مسار الصفحة (Player ESP > Survivor): كل جزء نص منفصل عشان العربية ما تنعكس
function G.addBreadcrumb(content, parentKey, childKey)
    local bc = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 24),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = ord(content)
    }, content)
    make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, bc)
    make("UIPadding", {PaddingLeft = UDim.new(0, 4)}, bc)

    local function part(key, color, order)
        local l = make("TextLabel", {
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.XY,
            Size = UDim2.fromOffset(0, 0),
            Font = Enum.Font.GothamBold,
            Text = "",
            TextColor3 = color,
            TextWrapped = false,
            TextTruncate = Enum.TextTruncate.None,
            TextSize = _G.MenuSettings.MenuTextSize,
            LayoutOrder = order
        }, bc)
        if key then bind(l, key) else l.Text = ">" end
        table.insert(G.menuLabels, l)
        return l
    end

    if childKey then
        part(parentKey, C.Dim, 1)
        part(nil, C.Dim, 2)
        part(childKey, C.White, 3)
    else
        part(parentKey, C.White, 1)
    end
end

---------------------------------------------------------------------
-- القائمة الجانبية: Player ESP يفتح تحته Survivor و Killer
---------------------------------------------------------------------
local PAGE_X, PAGE_Y = 300, 75
G.Pages = {}
G.currentPage = "Survivor"
G.switchId = 0

function G.createPage(name)
    local page = make("CanvasGroup", {
        Name = name,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(PAGE_X, PAGE_Y),
        Size = UDim2.fromOffset(565, 550),
        GroupTransparency = (name == G.currentPage) and 0 or 1,
        Visible = (name == G.currentPage)
    }, MainFrame)
    G.Pages[name] = page
    return page
end

G.PageSurvivor = G.createPage("Survivor")
G.PageKiller = G.createPage("Killer")
G.PageObjects = G.createPage("Objects ESP")
G.PageSettings = G.createPage("Settings")

G.sidebarButtons = {}
G.subButtons = {}
G.subPads = {}
G.expandVal = Instance.new("NumberValue")   -- 0 = مقفول ... 1 = مفتوح
G.expandTween = nil
G.expandedTarget = true
G.clickExpanded = true
G.lastChild = "Survivor"

function G.isChildPage()
    return G.currentPage == "Survivor" or G.currentPage == "Killer"
end

-- المؤشر ينزلق خلف الصفحة الحالية
G.Indicator = make("Frame", {
    BackgroundColor3 = C.Active,
    Position = UDim2.fromOffset(15, 75),
    Size = UDim2.fromOffset(250, 40)
}, G.Sidebar)
corner(G.Indicator, 6)
corner(make("Frame", {
    BackgroundColor3 = C.Accent,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 0.5, -10),
    Size = UDim2.fromOffset(3, 20)
}, G.Indicator), 2)

local nav = make("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(15, 75),
    Size = UDim2.new(1, -30, 1, -90)
}, G.Sidebar)
make("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, nav)

function G.navButton(parent, order, minH)
    local b = make("TextButton", {
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Size = UDim2.new(1, 0, 0, minH),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Enum.Font.GothamBold,
        Text = "",
        TextWrapped = true,
        TextTruncate = Enum.TextTruncate.None,
        TextSize = _G.MenuSettings.MenuTextSize,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = order
    }, parent)
    table.insert(G.menuLabels, b)
    return b
end

G.headerBtn = G.navButton(nav, 1, 40)
G.headerBtn.TextColor3 = G.isChildPage() and C.White or C.Dim
make("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 34), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4)}, G.headerBtn)
bind(G.headerBtn, "nav.player")

G.headerChev = make("TextLabel", {
    BackgroundTransparency = 1,
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, 26, 0, 0),
    Size = UDim2.new(0, 22, 1, 0),
    Font = Enum.Font.GothamBold,
    Text = ">",
    TextColor3 = C.Dim,
    TextSize = 15
}, G.headerBtn)

G.subFrame = make("Frame", {
    BackgroundTransparency = 1,
    ClipsDescendants = true,
    Size = UDim2.new(1, 0, 0, 0),
    LayoutOrder = 2
}, nav)

G.subInner = make("Frame", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y
}, G.subFrame)
make("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, G.subInner)
make("UIPadding", {PaddingLeft = UDim.new(0, 12)}, G.subInner)

function G.addSidebarItem(pageName, navKey, parent, order, minH, isSub)
    local btn = G.navButton(parent, order, minH)
    btn.TextColor3 = (pageName == G.currentPage) and C.White or C.Dim
    local pad = make("UIPadding", {
        PaddingLeft = UDim.new(0, isSub and 24 or 12),
        PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4)
    }, btn)
    bind(btn, navKey)

    btn.MouseEnter:Connect(function()
        if G.currentPage ~= pageName then tween(btn, 0.15, {TextColor3 = C.DimHover}) end
    end)
    btn.MouseLeave:Connect(function()
        if G.currentPage ~= pageName then tween(btn, 0.15, {TextColor3 = C.Dim}) end
    end)
    G.sidebarButtons[pageName] = btn
    if isSub then G.subPads[btn] = pad end
    return btn
end

G.survivorBtn = G.addSidebarItem("Survivor", "nav.survivor", G.subInner, 1, 32, true)
G.killerBtn = G.addSidebarItem("Killer", "nav.killer", G.subInner, 2, 32, true)
G.subButtons = {G.survivorBtn, G.killerBtn}
G.addSidebarItem("Objects ESP", "nav.objects", nav, 3, 40, false)
G.addSidebarItem("Settings", "nav.settings", nav, 4, 40, false)   -- Settings دائماً آخر عنصر

function G.layout()
    local f = G.expandVal.Value
    local nat = G.subInner.AbsoluteSize.Y / G.uiScaleFactor()
    G.subFrame.Size = UDim2.new(1, 0, 0, math.floor(nat * f + 0.5))
    G.headerChev.Rotation = 90 * f
    for i, b in ipairs(G.subButtons) do
        local fi = math.clamp((f - (i - 1) * 0.25) / 0.75, 0, 1)
        b.TextTransparency = 1 - fi
        G.subPads[b].PaddingLeft = UDim.new(0, 24 - 14 * (1 - fi))
    end
end
track(G.expandVal.Changed:Connect(G.layout))
track(G.subInner:GetPropertyChangedSignal("AbsoluteSize"):Connect(G.layout))
G.expandVal.Value = 1
G.layout()

function G.setExpanded(v)
    if G.expandedTarget == v then return end
    G.expandedTarget = v
    if G.expandTween then G.expandTween:Cancel() end
    G.expandTween = tween(G.expandVal, v and 0.42 or 0.3, {Value = v and 1 or 0}, Enum.EasingStyle.Quint)
end

function G.refreshNavColors()
    for name, b in pairs(G.sidebarButtons) do
        tween(b, 0.2, {TextColor3 = (name == G.currentPage) and C.White or C.Dim})
    end
    tween(G.headerBtn, 0.2, {TextColor3 = G.isChildPage() and C.White or C.Dim})
    tween(G.headerChev, 0.2, {TextColor3 = G.isChildPage() and C.White or C.Dim})
end

function G.switchPage(name)
    if name == G.currentPage or not G.Pages[name] then return end
    G.switchId += 1
    local id = G.switchId
    local oldPage, newPage = G.Pages[G.currentPage], G.Pages[name]
    G.currentPage = name
    if name == "Survivor" or name == "Killer" then
        G.lastChild = name
        G.clickExpanded = true
    end

    for _, p in pairs(G.Pages) do
        if p ~= oldPage and p ~= newPage then p.Visible = false end
    end
    G.refreshNavColors()

    tween(oldPage, 0.12, {GroupTransparency = 1})
    task.delay(0.12, function()
        if id ~= G.switchId then return end
        oldPage.Visible = false
        newPage.Position = UDim2.fromOffset(PAGE_X, PAGE_Y + 14)
        newPage.GroupTransparency = 1
        newPage.Visible = true
        tween(newPage, 0.3, {
            GroupTransparency = 0,
            Position = UDim2.fromOffset(PAGE_X, PAGE_Y)
        }, Enum.EasingStyle.Quint)
    end)
end

for name, b in pairs(G.sidebarButtons) do
    b.MouseButton1Click:Connect(function() G.switchPage(name) end)
end

G.headerBtn.MouseEnter:Connect(function()
    if not G.isChildPage() then tween(G.headerBtn, 0.15, {TextColor3 = C.DimHover}) end
end)
G.headerBtn.MouseLeave:Connect(function()
    if not G.isChildPage() then tween(G.headerBtn, 0.15, {TextColor3 = C.Dim}) end
end)
G.headerBtn.MouseButton1Click:Connect(function()
    if _G.MenuSettings.HoverMode then
        if not G.isChildPage() then G.switchPage(G.lastChild) end
    else
        G.clickExpanded = not G.clickExpanded
    end
end)

-- المؤشر يتبع زر الصفحة الحالية بنعومة (يتحدث تلقائياً مع أي تغيير بالحجم)
local ix, iy, iw, ih = 15, 75, 250, 40

function G.indicatorTarget()
    local btn = G.sidebarButtons[G.currentPage]
    if not btn or not btn.Parent then return ix, iy, iw, ih end
    local s = G.uiScaleFactor()
    local bp, bs, sp = btn.AbsolutePosition, btn.AbsoluteSize, G.Sidebar.AbsolutePosition
    return (bp.X - sp.X) / s, (bp.Y - sp.Y) / s, bs.X / s, bs.Y / s
end

G.collapseAt = nil

track(RunService.Heartbeat:Connect(function(dt)
    if G.menuVisible then
        local tx, ty, tw, th = G.indicatorTarget()
        local d = math.abs(tx - ix) + math.abs(ty - iy) + math.abs(tw - iw) + math.abs(th - ih)
        if d > 0.05 then
            local a = 1 - math.exp(-dt * 16)
            ix += (tx - ix) * a
            iy += (ty - iy) * a
            iw += (tw - iw) * a
            ih += (th - ih) * a
            G.Indicator.Position = UDim2.fromOffset(ix, iy)
            G.Indicator.Size = UDim2.fromOffset(iw, ih)
        elseif d > 0 then
            ix, iy, iw, ih = tx, ty, tw, th
            G.Indicator.Position = UDim2.fromOffset(ix, iy)
            G.Indicator.Size = UDim2.fromOffset(iw, ih)
        end
    end

    if not G.menuVisible then return end
    if _G.MenuSettings.HoverMode then
        local m = getMouse()
        local hp, hs = G.headerBtn.AbsolutePosition, G.headerBtn.AbsoluteSize
        local bottom = hp.Y + hs.Y
        if G.expandedTarget then
            bottom = G.subFrame.AbsolutePosition.Y + G.subInner.AbsoluteSize.Y
        end
        local over = m.X >= hp.X and m.X <= hp.X + hs.X and m.Y >= hp.Y and m.Y <= bottom
        if over or G.isChildPage() then
            G.collapseAt = nil
            G.setExpanded(true)
        elseif G.expandedTarget then
            G.collapseAt = G.collapseAt or (os.clock() + 0.15)
            if os.clock() >= G.collapseAt then
                G.setExpanded(false)
                G.collapseAt = nil
            end
        end
    else
        G.setExpanded(G.clickExpanded)
    end
end))

---------------------------------------------------------------------
-- مساعدات نصوص اللعبة (مشتركة بين المعاينة والعرض الحقيقي)
---------------------------------------------------------------------
G.ANCHORS = {above = Vector2.new(0.5, 1), center = Vector2.new(0.5, 0.5), below = Vector2.new(0.5, 0)}
G.POSKEY = {above = "top", center = "center", below = "bottom"}

function G.fmtDist(idx, meters)
    return string.format(G.DistFormats[idx] or G.DistFormats[1], meters)
end

function G.spaceText(s)
    local ok, r = pcall(function()
        local out = {}
        for _, cp in utf8.codes(s) do out[#out + 1] = utf8.char(cp) end
        return table.concat(out, " ")
    end)
    return ok and r or s
end

G.labelMeta = setmetatable({}, {__mode = "k"})

function G.styleLabel(lbl, cfg)
    lbl.TextSize = cfg.size
    local f = G.gameFace(cfg.bold)
    if f then pcall(function() lbl.FontFace = f end) end
    lbl.TextStrokeTransparency = 1 - cfg.outline / 100
    lbl.AnchorPoint = G.ANCHORS[cfg.pos] or G.ANCHORS.above
    local m = G.labelMeta[lbl] or {}
    G.labelMeta[lbl] = m
    m.ver = G.styleVersion
    m.baseT = 1 - cfg.opacity / 100
    lbl.TextTransparency = m.baseT
end

function G.placeLabel(lbl, cfg, anchors)
    local p = anchors[G.POSKEY[cfg.pos] or "top"]
    lbl.Position = UDim2.fromOffset(math.floor(p.X + cfg.ox + 0.5), math.floor(p.Y + cfg.oy + 0.5))
end

---------------------------------------------------------------------
-- أنواع الأغراض (Objects ESP)
---------------------------------------------------------------------
G.ObjectTypes = {
    {key = "Generator", env = true, color = Color3.fromRGB(80, 200, 255), contains = {"generator"}},
    {key = "Pallet", env = true, color = Color3.fromRGB(255, 220, 50), contains = {"pallet"}},
    {key = "Window", env = true, color = Color3.fromRGB(255, 150, 50), contains = {"window"}},
    {key = "Totem", env = true, color = Color3.fromRGB(170, 120, 255), contains = {"totem"}},
    {key = "Hatch", env = true, color = Color3.fromRGB(50, 255, 140), contains = {"hatch"}},
    {key = "EscapeDoor", env = true, color = Color3.fromRGB(50, 255, 50), contains = {"escapedoor", "exitgate", "exitdoor"}},
    {key = "Breakable", env = true, color = Color3.fromRGB(210, 210, 210), contains = {"breakable"}},
    {key = "Locker", env = true, color = Color3.fromRGB(150, 200, 255), contains = {"locker"}},
    {key = "MeatHook", env = true, color = Color3.fromRGB(255, 70, 70), contains = {"meathook", "hook"}},
    {key = "BreakableWall", env = false, color = Color3.fromRGB(210, 210, 210), contains = {"breakablewall"}},
    {key = "Item", env = false, color = Color3.fromRGB(255, 255, 255), exact = {"item"}},
    {key = "Traps", env = false, color = Color3.fromRGB(255, 60, 60), contains = {"trap"}},
    {key = "CenobiteBox", env = false, color = Color3.fromRGB(255, 80, 200), contains = {"cenobite", "lamentbox", "puzzlebox"}},
    {key = "ConjoinedTwin", env = false, color = Color3.fromRGB(255, 120, 120), contains = {"conjoined", "twin"}},
    {key = "Zombie", env = false, color = Color3.fromRGB(120, 255, 120), contains = {"zombie"}},
    {key = "Drone", env = false, color = Color3.fromRGB(80, 160, 255), contains = {"drone"}},
    {key = "Guard", env = false, color = Color3.fromRGB(255, 170, 60), exact = {"guard"}},
    {key = "Dog", env = false, color = Color3.fromRGB(200, 160, 100), exact = {"dog"}}
}

G.objByKey = {}
G.ObjState = {on = {}, color = {}, showDist = true, range = 150, maxLabels = 10}
G.ObjEntries = {}
for _, ot in ipairs(G.ObjectTypes) do
    G.objByKey[ot.key] = ot
    G.ObjState.on[ot.key] = false
    G.ObjState.color[ot.key] = ot.color
    G.ObjEntries[ot.key] = {}
end

---------------------------------------------------------------------
-- لوحة الألوان (قابلة لإعادة الاستخدام: اللاعبين + الأغراض)
---------------------------------------------------------------------
function G.createColorPanel(col, titleFn)
    local P = {open = false, key = nil, onPick = nil}

    local card = make("CanvasGroup", {
        BackgroundColor3 = C.Card,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = ord(col),
        Visible = false,
        GroupTransparency = 1
    }, col)
    corner(card, 8)
    make("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, card)
    make("UIPadding", {
        PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)
    }, card)
    local popScale = make("UIScale", {}, card)

    local title = make("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 24),
        Font = Enum.Font.GothamBold,
        Text = "",
        TextColor3 = Color3.fromRGB(215, 215, 230),
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 1
    }, card)
    G.autoLabel(title, G.contentLabels, G.groupSize(G.contentLabels))

    local pickRow = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 170),
        LayoutOrder = 2
    }, card)

    local hue = make("TextButton", {
        BackgroundColor3 = C.White,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 28, 1, 0),
        AutoButtonColor = false,
        Text = ""
    }, pickRow)
    corner(hue, 6)
    make("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0))
        }),
        Rotation = 90
    }, hue)
    local hueMarker = make("Frame", {
        BackgroundColor3 = C.White,
        Position = UDim2.new(0, -3, 0, -2),
        Size = UDim2.new(1, 6, 0, 4)
    }, hue)
    corner(hueMarker, 2)
    make("UIStroke", {Color = Color3.fromRGB(0, 0, 0), Thickness = 1}, hueMarker)

    local sv = make("TextButton", {
        BackgroundColor3 = Color3.fromRGB(255, 0, 0),
        Size = UDim2.new(1, -40, 1, 0),
        AutoButtonColor = false,
        Text = ""
    }, pickRow)
    corner(sv, 6)

    local whiteLayer = make("Frame", {BackgroundColor3 = C.White, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1)}, sv)
    corner(whiteLayer, 6)
    make("UIGradient", {
        Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
    }, whiteLayer)
    local blackLayer = make("Frame", {BackgroundColor3 = Color3.fromRGB(0, 0, 0), BorderSizePixel = 0, Size = UDim2.fromScale(1, 1)}, sv)
    corner(blackLayer, 6)
    make("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})
    }, blackLayer)

    local svCursor = make("Frame", {
        BackgroundColor3 = C.White,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(10, 10)
    }, sv)
    corner(svCursor, 5)
    make("UIStroke", {Color = Color3.fromRGB(0, 0, 0), Thickness = 1.5}, svCursor)

    local sHue, sSat, sVal = 0, 1, 1
    local function pickerVisuals()
        sv.BackgroundColor3 = Color3.fromHSV(sHue, 1, 1)
        svCursor.Position = UDim2.new(sSat, 0, 1 - sVal, 0)
        hueMarker.Position = UDim2.new(0, -3, sHue, -2)
    end

    local swRow = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 36),
        LayoutOrder = 3
    }, card)
    make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, swRow)

    local swatches = {}
    local function selectSwatch(idx)
        for j, s in ipairs(swatches) do
            tween(s.stroke, 0.15, {Transparency = (j == idx) and 0 or 1})
        end
    end

    local function pick(colr, instant, pulse)
        if P.onPick then P.onPick(colr, instant, pulse) end
    end

    for i, pc in ipairs(paletteColors) do
        local b = make("TextButton", {
            BackgroundColor3 = pc,
            AutoButtonColor = false,
            Size = UDim2.fromOffset(34, 28),
            Text = "",
            LayoutOrder = i
        }, swRow)
        corner(b, 6)
        local stroke = make("UIStroke", {
            Color = C.White, Thickness = 2, Transparency = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        }, b)
        local sc = make("UIScale", {}, b)
        swatches[i] = {stroke = stroke}
        b.MouseEnter:Connect(function() tween(sc, 0.12, {Scale = 1.1}) end)
        b.MouseLeave:Connect(function() tween(sc, 0.12, {Scale = 1}) end)
        b.MouseButton1Click:Connect(function()
            pick(pc, false, true)
            selectSwatch(i)
            sHue, sSat, sVal = Color3.toHSV(pc)
            pickerVisuals()
        end)
    end

    sv.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            G.startDrag(function(pos)
                local p, s = sv.AbsolutePosition, sv.AbsoluteSize
                if s.X <= 0 or s.Y <= 0 then return end
                sSat = math.clamp((pos.X - p.X) / s.X, 0, 1)
                sVal = 1 - math.clamp((pos.Y - p.Y) / s.Y, 0, 1)
                pickerVisuals()
                pick(Color3.fromHSV(sHue, sSat, sVal), true, false)
                selectSwatch(0)
            end)
        end
    end)

    hue.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            G.startDrag(function(pos)
                local p, s = hue.AbsolutePosition, hue.AbsoluteSize
                if s.Y <= 0 then return end
                sHue = math.clamp((pos.Y - p.Y) / s.Y, 0, 1)
                pickerVisuals()
                pick(Color3.fromHSV(sHue, sSat, sVal), true, false)
                selectSwatch(0)
            end)
        end
    end)

    function P.setColorSilent(colr)
        sHue, sSat, sVal = Color3.toHSV(colr)
        local idx = 0
        for i, pc in ipairs(paletteColors) do
            if pc == colr then idx = i end
        end
        selectSwatch(idx)
        pickerVisuals()
    end

    function P.refreshTitle()
        if P.key then title.Text = titleFn(P.key) end
    end

    function P.show(key, colr, onPick)
        P.key = key
        P.onPick = onPick
        P.setColorSilent(colr)
        P.refreshTitle()
        if not P.open then
            P.open = true
            card.Visible = true
            card.GroupTransparency = 1
            popScale.Scale = 0.96
            tween(card, 0.25, {GroupTransparency = 0})
            tween(popScale, 0.3, {Scale = 1}, Enum.EasingStyle.Back)
        end
    end

    function P.hide()
        if not P.open then return end
        P.open = false
        tween(card, 0.2, {GroupTransparency = 1})
        task.delay(0.22, function()
            if not P.open then card.Visible = false end
        end)
    end

    table.insert(G.langListeners, function() P.refreshTitle() end)
    return P
end

---------------------------------------------------------------------
-- صفحات Survivor / Killer
---------------------------------------------------------------------
function G.buildPlayerPage(page, prefix, navKey)
    local _, content = G.newScroller(page)
    G.addBreadcrumb(content, "nav.player", navKey)
    local _, left, right = G.newColumns(content)

    local card = G.newCard(left, navKey, G.contentLabels)

    local rowsHolder = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = ord(card)
    }, card)

    -- إطار التحديد: ينزلق خلف الخيار اللي تعدّل لونه
    local selector = make("Frame", {
        BackgroundColor3 = C.Accent,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 34)
    }, rowsHolder)
    corner(selector, 6)
    local selStroke = make("UIStroke", {
        Color = C.Accent, Thickness = 1.5, Transparency = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, selector)

    local rowsC = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y
    }, rowsHolder)
    make("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}, rowsC)

    local panel
    local currentTarget = "Name"
    local selectorShown = false
    local targets = {}
    local refreshPill, updateTargetVisuals

    G.createToggle(rowsC, "opt.enabled", false, G.contentLabels, function(v)
        _G[prefix .. "_Enabled"] = v
    end, prefix .. "_Enabled")

    local rowDefs = {
        {key = "Name", opt = "opt.name", gkey = prefix .. "_Color"},
        {key = "Distance", opt = "opt.distance", gkey = prefix .. "_DistanceColor"},
        {key = "Highlight", opt = "opt.highlight", gkey = prefix .. "_HighlightColor"},
        {key = "Skeleton", opt = "opt.skeleton", gkey = prefix .. "_SkeletonColor"}
    }

    local function placeSelector(instant)
        local t = targets[currentTarget]
        if not t then return end
        local s = G.uiScaleFactor()
        local y = (t.btn.AbsolutePosition.Y - rowsHolder.AbsolutePosition.Y) / s
        local h = t.btn.AbsoluteSize.Y / s
        if instant then
            selector.Position = UDim2.fromOffset(0, y)
            selector.Size = UDim2.new(1, 0, 0, h)
        else
            tween(selector, 0.3, {Position = UDim2.fromOffset(0, y), Size = UDim2.new(1, 0, 0, h)}, Enum.EasingStyle.Quint)
        end
    end

    for _, def in ipairs(rowDefs) do
        local labelKey = def.opt
        if def.key == "Skeleton" and not hasDrawing then labelKey = "opt.skeletonNA" end

        local btn, lbl = G.createToggle(rowsC, labelKey, false, G.contentLabels, function(v)
            _G[prefix .. "_" .. def.key] = v
        end, prefix .. "_" .. def.key, 64)

        lbl.TextStrokeTransparency = 0.4
        lbl.TextColor3 = _G[def.gkey]

        local dot = make("Frame", {
            BackgroundColor3 = _G[def.gkey],
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -34, 0, 11),
            Size = UDim2.fromOffset(12, 12)
        }, btn)
        corner(dot, 6)
        local ring = make("UIStroke", {Color = C.BoxBorder, Thickness = 1}, dot)
        local dotScale = make("UIScale", {}, dot)

        local chev = make("TextButton", {
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -6, 0, 5),
            Size = UDim2.fromOffset(24, 24),
            AutoButtonColor = false,
            Font = Enum.Font.GothamBold,
            Text = ">",
            TextSize = 15,
            TextColor3 = C.Dim
        }, btn)

        targets[def.key] = {
            gkey = def.gkey, opt = def.opt, btn = btn, label = lbl,
            dot = dot, ring = ring, dotScale = dotScale, chevron = chev
        }

        chev.MouseEnter:Connect(function() tween(chev, 0.12, {TextColor3 = C.White}) end)
        chev.MouseLeave:Connect(function()
            local active = panel.open and currentTarget == def.key
            tween(chev, 0.12, {TextColor3 = active and C.Accent or C.Dim})
        end)
        chev.MouseButton1Click:Connect(function()
            if panel.open and currentTarget == def.key then
                panel.hide()
            else
                currentTarget = def.key
                local key = def.key
                panel.show(key, _G[def.gkey], function(colr, instant, pulse)
                    local t = targets[key]
                    _G[t.gkey] = colr
                    if instant then
                        t.dot.BackgroundColor3 = colr
                        t.label.TextColor3 = colr
                    else
                        tween(t.dot, 0.18, {BackgroundColor3 = colr})
                        tween(t.label, 0.18, {TextColor3 = colr})
                    end
                    if pulse then
                        t.dotScale.Scale = 1.5
                        tween(t.dotScale, 0.35, {Scale = 1}, Enum.EasingStyle.Back)
                    end
                    G.markDirty()
                end)
            end
            updateTargetVisuals(true)
        end)
    end

    -- شريط الحالة
    local pill = make("Frame", {
        BackgroundColor3 = C.PillOff,
        Size = UDim2.new(1, 0, 0, 28),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = ord(card)
    }, card)
    corner(pill, 6)
    local pillStroke = make("UIStroke", {
        Color = C.Accent, Thickness = 1, Transparency = 0.7,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, pill)
    local pillScale = make("UIScale", {}, pill)
    local pillChip = make("Frame", {
        BackgroundColor3 = _G[prefix .. "_Color"],
        BackgroundTransparency = 0.6,
        Position = UDim2.fromOffset(10, 8),
        Size = UDim2.fromOffset(12, 12)
    }, pill)
    corner(pillChip, 6)
    make("UIStroke", {Color = C.White, Thickness = 1, Transparency = 0.4}, pillChip)
    local pillLbl = make("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(30, 0),
        Size = UDim2.new(1, -38, 0, 28),
        Font = Enum.Font.GothamBold,
        RichText = true,
        Text = "",
        TextColor3 = C.Dim,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center
    }, pill)
    G.autoLabel(pillLbl, G.contentLabels, G.groupSize(G.contentLabels))
    make("UIPadding", {PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 2)}, pillLbl)

    panel = G.createColorPanel(right, function(key)
        return T("picker.title", T(targets[key].opt))
    end)

    refreshPill = function()
        if panel.open then
            pillLbl.Text = T("hint.editing", '<font color="#FFFFFF">' .. T(targets[currentTarget].opt) .. '</font>')
        else
            pillLbl.Text = T("hint.pick")
        end
        tween(pillLbl, 0.2, {TextColor3 = panel.open and Color3.fromRGB(205, 205, 220) or C.Dim})
        tween(pillStroke, 0.2, {Transparency = panel.open and 0.1 or 0.7})
        tween(pill, 0.2, {BackgroundColor3 = panel.open and C.PillOn or C.PillOff})
        tween(pillChip, 0.2, {BackgroundTransparency = panel.open and 0 or 0.6})
    end

    local function flashPill()
        pill.BackgroundColor3 = Color3.fromRGB(95, 60, 200)
        tween(pill, 0.5, {BackgroundColor3 = panel.open and C.PillOn or C.PillOff})
        pillScale.Scale = 1.04
        tween(pillScale, 0.35, {Scale = 1}, Enum.EasingStyle.Back)
    end

    updateTargetVisuals = function(flash)
        local open = panel.open
        for key, t in pairs(targets) do
            local on = open and key == currentTarget
            tween(t.chevron, 0.2, {TextColor3 = on and C.Accent or C.Dim})
            tween(t.ring, 0.2, {Color = on and C.White or C.BoxBorder, Thickness = on and 2 or 1})
        end
        if open then
            pillChip.BackgroundColor3 = _G[targets[currentTarget].gkey]
            if not selectorShown then
                selectorShown = true
                placeSelector(true)
                tween(selector, 0.25, {BackgroundTransparency = 0.86})
                tween(selStroke, 0.25, {Transparency = 0.15})
            else
                placeSelector(false)
            end
            if flash then flashPill() end
        elseif selectorShown then
            selectorShown = false
            tween(selector, 0.2, {BackgroundTransparency = 1})
            tween(selStroke, 0.2, {Transparency = 1})
        end
        refreshPill()
    end

    -- لو تغيّر حجم الصفوف (حجم الخط) نعيد مكان إطار التحديد
    track(rowsC:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if selectorShown then placeSelector(true) end
    end))

    -- لما اللوحة تنقفل من أي مكان نحدّث المؤشرات
    local lastOpen = false
    track(RunService.Heartbeat:Connect(function()
        if panel.open ~= lastOpen then
            lastOpen = panel.open
            updateTargetVisuals(false)
        end
    end))

    for key, t in pairs(targets) do
        G.registerControl(t.gkey, function() return _G[t.gkey] end, function(v)
            local colr = G.toColor(v)
            if colr then
                _G[t.gkey] = colr
                t.dot.BackgroundColor3 = colr
                t.label.TextColor3 = colr
                if panel.open and panel.key == key then panel.setColorSilent(colr) end
            end
        end)
    end

    table.insert(G.langListeners, function() refreshPill() end)
    refreshPill()
end

G.buildPlayerPage(G.PageSurvivor, "Survivor", "nav.survivor")
G.buildPlayerPage(G.PageKiller, "Killer", "nav.killer")

---------------------------------------------------------------------
-- صفحة Objects ESP
---------------------------------------------------------------------
function G.buildObjectsPage(page)
    local _, content = G.newScroller(page)
    G.addBreadcrumb(content, "nav.objects", nil)
    local _, left, right = G.newColumns(content)

    local panel = G.createColorPanel(right, function(key) return T("picker.title", T("obj." .. key)) end)
    local envCard = G.newCard(left, "obj.env", G.contentLabels)
    local spCard = G.newCard(right, "obj.special", G.contentLabels)

    local dots = {}
    local activeKey = nil

    local function refreshRings()
        for key, d in pairs(dots) do
            local on = panel.open and activeKey == key
            tween(d.ring, 0.2, {Color = on and C.White or C.BoxBorder, Thickness = on and 2 or 1})
        end
    end

    local function setObjColor(key, colr, instant, pulse)
        local d = dots[key]
        G.ObjState.color[key] = colr
        if instant then
            d.dot.BackgroundColor3 = colr
            d.label.TextColor3 = colr
        else
            tween(d.dot, 0.18, {BackgroundColor3 = colr})
            tween(d.label, 0.18, {TextColor3 = colr})
        end
        if pulse then
            d.scale.Scale = 1.5
            tween(d.scale, 0.35, {Scale = 1}, Enum.EasingStyle.Back)
        end
        G.markDirty()
    end

    for _, ot in ipairs(G.ObjectTypes) do
        local key = ot.key
        local parentCard = ot.env and envCard or spCard
        local btn, lbl = G.createToggle(parentCard, "obj." .. key, false, G.contentLabels, function(v)
            G.ObjState.on[key] = v
        end, "Obj_" .. key, 44)

        lbl.TextStrokeTransparency = 0.5
        lbl.TextColor3 = G.ObjState.color[key]

        local dot = make("TextButton", {
            BackgroundColor3 = G.ObjState.color[key],
            AutoButtonColor = false,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -8, 0, 9),
            Size = UDim2.fromOffset(16, 16),
            Text = ""
        }, btn)
        corner(dot, 8)
        local ring = make("UIStroke", {Color = C.BoxBorder, Thickness = 1}, dot)
        local dotScale = make("UIScale", {}, dot)
        dots[key] = {dot = dot, ring = ring, scale = dotScale, label = lbl}

        dot.MouseEnter:Connect(function() tween(dotScale, 0.12, {Scale = 1.2}) end)
        dot.MouseLeave:Connect(function() tween(dotScale, 0.12, {Scale = 1}) end)
        dot.MouseButton1Click:Connect(function()
            if panel.open and activeKey == key then
                panel.hide()
            else
                activeKey = key
                panel.show(key, G.ObjState.color[key], function(colr, instant, pulse)
                    setObjColor(key, colr, instant, pulse)
                end)
            end
            refreshRings()
        end)

        G.registerControl("ObjColor_" .. key, function() return G.ObjState.color[key] end, function(v)
            local colr = G.toColor(v)
            if colr then
                setObjColor(key, colr, true)
                if panel.open and panel.key == key then panel.setColorSilent(colr) end
            end
        end)
    end

    local display = G.newCard(left, "obj.display", G.contentLabels)
    G.createToggle(display, "obj.showDistance", true, G.contentLabels, function(v)
        G.ObjState.showDist = v
    end, "Obj_ShowDistance")
    G.createSlider(display, "obj.range", 30, 600, 150, function(v) G.ObjState.range = v end, "Obj_Range", G.contentLabels)
    G.createSlider(display, "obj.maxLabels", 3, 30, 10, function(v) G.ObjState.maxLabels = v end, "Obj_MaxLabels", G.contentLabels)
end

G.buildObjectsPage(G.PageObjects)

---------------------------------------------------------------------
-- صفحة Settings (تبويبات: General / Appearance / ESP Text / World)
---------------------------------------------------------------------
G.keyListening = false
G.refreshKeyBtn = function() end
G.toast = function() end
G.refreshProfileList = function() end
G.applyAppearance = function() end

G.KEY_SHORT = {
    Delete = "DEL", Insert = "INS", RightShift = "R-SHIFT", LeftShift = "L-SHIFT",
    RightControl = "R-CTRL", LeftControl = "L-CTRL", RightAlt = "R-ALT", LeftAlt = "L-ALT",
    PageUp = "PGUP", PageDown = "PGDN", Return = "ENTER", Backspace = "BKSP"
}
function G.keyName(kc)
    return G.KEY_SHORT[kc.Name] or string.upper(kc.Name)
end

G.fixKey = Enum.KeyCode.End

function G.applyMenuKey(kc)
    local which = G.keyListening
    G.keyListening = false
    if kc ~= Enum.KeyCode.Escape and which then
        if which == "fix" then G.fixKey = kc else menuKey = kc end
        G.markDirty()
    end
    G.refreshKeyBtn()
end

G.registerControl("Menu.FixKey", function() return G.fixKey.Name end, function(v)
    if type(v) == "string" then
        local ok, kc = pcall(function() return Enum.KeyCode[v] end)
        if ok and kc then G.fixKey = kc end
    end
    G.refreshKeyBtn()
end)

G.registerControl("Menu.Key", function() return menuKey.Name end, function(v)
    if type(v) == "string" then
        local ok, kc = pcall(function() return Enum.KeyCode[v] end)
        if ok and kc then menuKey = kc end
    end
    G.refreshKeyBtn()
end)

function G.buildSettings()
    local _, sContent = G.newScroller(G.PageSettings)
    G.addBreadcrumb(sContent, "nav.settings", nil)

    local currentTab = "general"
    local tabFrames = {}
    local switchTab
    local refreshEditor

    local tabItems = {
        {id = "general", key = "tab.general"}, {id = "appearance", key = "tab.appearance"},
        {id = "text", key = "tab.text"}, {id = "world", key = "tab.world"}, {id = "camera", key = "tab.camera"}
    }
    G.createPills(sContent, tabItems, function() return currentTab end, function(id) switchTab(id) end, G.menuLabels, 4)

    local tabOrder = ord(sContent)
    local function newTab(id)
        local g = make("CanvasGroup", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = tabOrder,
            Visible = (id == currentTab)
        }, sContent)
        tabFrames[id] = g
        local _, l, r = G.newColumns(g)
        return l, r
    end

    ------------------------------------------------------------------
    -- تبويب General
    ------------------------------------------------------------------
    local gl, gr = newTab("general")

    local prefs = G.newCard(gl, "set.prefs", G.menuLabels)
    G.createToggle(prefs, "set.hover", true, G.menuLabels, function(v)
        _G.MenuSettings.HoverMode = v
    end, "Menu.HoverMode")

    G.createSlider(prefs, "set.menuSize", 10, 40, 14, function(v)
        _G.MenuSettings.MenuTextSize = v
        for _, l in ipairs(G.menuLabels) do
            if l and l.Parent then G.applyTextSize(l, v) end
        end
        G.refreshPillGrids()
    end, "Menu.MenuTextSize", G.menuLabels)

    G.createSlider(prefs, "set.contentSize", 10, 40, 14, function(v)
        _G.MenuSettings.ContentTextSize = v
        for _, l in ipairs(G.contentLabels) do
            if l and l.Parent then G.applyTextSize(l, v) end
        end
        G.refreshPillGrids()
    end, "Menu.ContentTextSize", G.menuLabels)

    local nameSlider = G.createSlider(prefs, "set.nameSize", 10, 60, G.TextCfg.pname.size, function(v)
        G.TextCfg.pname.size = v
        G.bumpStyle()
        if refreshEditor then refreshEditor() end
    end, nil, G.menuLabels)

    -- أزرار الاختصارات: فتح القائمة + إصلاح الكاميرا
    local function makeKeyRow(labelKey, which, getKey)
        local keyRow = make("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 36),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = ord(prefs)
        }, prefs)
        local keyLbl = make("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(6, 0),
            Size = UDim2.new(1, -130, 0, 36),
            Font = Enum.Font.GothamBold,
            Text = "",
            TextColor3 = Color3.fromRGB(240, 240, 255),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center
        }, keyRow)
        bind(keyLbl, labelKey)
        G.autoLabel(keyLbl, G.menuLabels, G.groupSize(G.menuLabels))

        local keyBtn = make("TextButton", {
            BackgroundColor3 = C.Row,
            AutoButtonColor = false,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -4, 0, 4),
            Size = UDim2.fromOffset(96, 28),
            AutomaticSize = Enum.AutomaticSize.XY,
            Font = Enum.Font.GothamBold,
            Text = "",
            TextColor3 = C.White,
            TextWrapped = false,
            TextTruncate = Enum.TextTruncate.None,
            TextSize = G.groupSize(G.menuLabels)
        }, keyRow)
        corner(keyBtn, 6)
        make("UIPadding", {
            PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
            PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 2)
        }, keyBtn)
        local keyStroke = make("UIStroke", {
            Color = C.BoxBorder, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        }, keyBtn)
        table.insert(G.menuLabels, keyBtn)

        keyBtn.MouseButton1Click:Connect(function()
            if G.keyListening == which then G.keyListening = false else G.keyListening = which end
            G.refreshKeyBtn()
        end)
        return function()
            local listening = (G.keyListening == which)
            keyBtn.Text = listening and T("set.keyListening") or G.keyName(getKey())
            tween(keyStroke, 0.15, {Color = listening and C.Accent or C.BoxBorder})
            tween(keyBtn, 0.15, {BackgroundColor3 = listening and C.PillOn or C.Row})
        end
    end

    local refreshMenuKey = makeKeyRow("set.menuKey", "menu", function() return menuKey end)
    local refreshFixKey = makeKeyRow("set.fixKey", "fix", function() return G.fixKey end)
    G.refreshKeyBtn = function()
        refreshMenuKey()
        refreshFixKey()
    end
    table.insert(G.langListeners, function() G.refreshKeyBtn() end)
    G.refreshKeyBtn()

    -- اللغة
    local langCard = G.newCard(gl, "set.language", G.menuLabels)
    local langItems = {}
    for _, l in ipairs(G.LangList) do langItems[#langItems + 1] = {id = l.id, text = l.name, size = (l.id == "ar") and 16 or 13} end
    local refreshLangPills = G.createPills(langCard, langItems, function() return G.currentLang end, function(id)
        G.setLanguage(id)
    end, G.menuLabels)

    -- نطاق اللاعبين
    local rangeCard = G.newCard(gl, "set.range", G.menuLabels)
    G.createSlider(rangeCard, "set.rangePlayers", 50, 2000, 600, function(v)
        _G.MenuSettings.PlayerRange = v
    end, "Menu.PlayerRange", G.menuLabels)

    -- الإعدادات المحفوظة
    local pc = G.newCard(gr, "set.profiles", G.menuLabels)

    local userRow = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = ord(pc)
    }, pc)
    make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, userRow)
    make("UIPadding", {PaddingLeft = UDim.new(0, 6)}, userRow)
    local userCaption = make("TextLabel", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.fromOffset(0, 0),
        Font = Enum.Font.GothamBold,
        Text = "",
        TextColor3 = C.Dim,
        TextWrapped = false,
        TextTruncate = Enum.TextTruncate.None,
        TextSize = G.groupSize(G.menuLabels),
        LayoutOrder = 1
    }, userRow)
    bind(userCaption, "set.user")
    table.insert(G.menuLabels, userCaption)
    local userName = make("TextLabel", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.fromOffset(0, 0),
        Font = Enum.Font.GothamBold,
        Text = LocalPlayer.Name,
        TextColor3 = C.Text,
        TextWrapped = false,
        TextTruncate = Enum.TextTruncate.None,
        TextSize = G.groupSize(G.menuLabels),
        LayoutOrder = 2
    }, userRow)
    table.insert(G.menuLabels, userName)

    local nameBox = make("TextBox", {
        BackgroundColor3 = C.Row,
        Size = UDim2.new(1, 0, 0, 34),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Enum.Font.GothamBold,
        Text = "",
        PlaceholderText = "",
        PlaceholderColor3 = C.Dim,
        TextColor3 = C.Text,
        TextSize = G.groupSize(G.menuLabels),
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = ord(pc)
    }, pc)
    corner(nameBox, 6)
    make("UIPadding", {
        PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
        PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4)
    }, nameBox)
    bind(nameBox, "set.profileName", {prop = "PlaceholderText"})
    table.insert(G.menuLabels, nameBox)
    local nameStroke = make("UIStroke", {
        Color = C.Accent, Thickness = 1, Transparency = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, nameBox)
    nameBox.Focused:Connect(function() tween(nameStroke, 0.15, {Transparency = 0.2}) end)

    local saveBtn = G.createButton(pc, "set.save", G.menuLabels, function() end)

    local listWrap = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 170),
        LayoutOrder = ord(pc)
    }, pc)
    local listFrame = make("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = C.BoxBorder,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    }, listWrap)
    make("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, listFrame)
    make("UIPadding", {PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 2)}, listFrame)

    local emptyLbl = make("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.new(1, -12, 0, 24),
        Font = Enum.Font.GothamBold,
        Text = "",
        TextColor3 = C.Dim,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top
    }, listWrap)
    bind(emptyLbl, "set.noProfiles")
    G.autoLabel(emptyLbl, G.menuLabels, G.groupSize(G.menuLabels))

    local toastLbl = make("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = " ",
        TextColor3 = Color3.fromRGB(120, 230, 150),
        TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = ord(pc)
    }, pc)
    G.autoLabel(toastLbl, G.menuLabels, math.max(11, G.groupSize(G.menuLabels) - 2))
    make("UIPadding", {PaddingLeft = UDim.new(0, 6)}, toastLbl)

    local toastToken = 0
    G.toast = function(text, isError, duration)
        toastToken += 1
        local id = toastToken
        toastLbl.Text = text
        toastLbl.TextColor3 = isError and Color3.fromRGB(255, 130, 110) or Color3.fromRGB(120, 230, 150)
        toastLbl.TextTransparency = 1
        tween(toastLbl, 0.2, {TextTransparency = 0})
        task.delay(duration or 2.6, function()
            if id == toastToken then tween(toastLbl, 0.4, {TextTransparency = 1}) end
        end)
    end

    G.onAutoSaved = function(ok)
        if ok then G.toast(T("set.autosaved")) end
    end

    local function loadProfile(name)
        local snap = G.StoreData.profiles[name]
        if not snap then return end
        G.applySnapshot(snap)
        refreshLangPills()
        G.StoreData.lastProfile = name
        G.markDirty()
        G.writeStore()
        G.refreshProfileList()
        G.toast(T("set.loaded", name))
    end

    local function saveProfile(name)
        name = string.gsub(name or "", "^%s+", "")
        name = string.gsub(name, "%s+$", "")
        if name == "" then
            G.toast(T("set.needName"), true)
            return
        end
        local chars = utf8.len(name)
        if chars and chars > 30 then
            name = string.sub(name, 1, utf8.offset(name, 31) - 1)
        end
        G.StoreData.profiles[name] = G.snapshot()
        G.StoreData.lastProfile = name
        G.writeStore()
        G.refreshProfileList()
        G.toast(T("set.saved", name))
    end

    local function deleteProfile(name)
        G.StoreData.profiles[name] = nil
        if G.StoreData.lastProfile == name then G.StoreData.lastProfile = nil end
        G.writeStore()
        G.refreshProfileList()
        G.toast(T("set.deleted", name))
    end

    G.refreshProfileList = function()
        for _, ch in ipairs(listFrame:GetChildren()) do
            if ch:IsA("Frame") then ch:Destroy() end
        end
        local names = {}
        for n in pairs(G.StoreData.profiles) do names[#names + 1] = n end
        table.sort(names)
        emptyLbl.Visible = (#names == 0)

        for i, n in ipairs(names) do
            local isCurrent = (G.StoreData.lastProfile == n)
            local row = make("Frame", {
                BackgroundColor3 = C.Row,
                Size = UDim2.new(1, 0, 0, 34),
                AutomaticSize = Enum.AutomaticSize.Y,
                LayoutOrder = i
            }, listFrame)
            corner(row, 6)
            if isCurrent then
                make("UIStroke", {
                    Color = C.Accent, Thickness = 1, Transparency = 0.3,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                }, row)
            end

            local nl = make("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(8, 0),
                Size = UDim2.new(1, -108, 0, 34),
                Font = Enum.Font.GothamBold,
                Text = n,
                TextColor3 = isCurrent and C.White or C.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center
            }, row)
            G.autoLabel(nl, G.menuLabels, G.groupSize(G.menuLabels))

            local loadBtn = make("TextButton", {
                BackgroundColor3 = C.Accent,
                AutoButtonColor = false,
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -34, 0, 5),
                Size = UDim2.fromOffset(62, 24),
                Font = Enum.Font.GothamBold,
                Text = "",
                TextColor3 = C.White
            }, row)
            corner(loadBtn, 5)
            bind(loadBtn, "set.load")
            G.fitLabel(loadBtn, G.menuLabels, G.groupSize(G.menuLabels))
            make("UIPadding", {
                PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
                PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3)
            }, loadBtn)
            loadBtn.MouseEnter:Connect(function() tween(loadBtn, 0.12, {BackgroundColor3 = C.AccentHover}) end)
            loadBtn.MouseLeave:Connect(function() tween(loadBtn, 0.12, {BackgroundColor3 = C.Accent}) end)
            loadBtn.MouseButton1Click:Connect(function() loadProfile(n) end)

            local delBtn = make("TextButton", {
                BackgroundTransparency = 1,
                AutoButtonColor = false,
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -4, 0, 6),
                Size = UDim2.fromOffset(22, 22),
                Text = ""
            }, row)
            local xa = make("Frame", {
                BackgroundColor3 = C.Dim, BorderSizePixel = 0,
                AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(11, 2), Rotation = 45
            }, delBtn)
            corner(xa, 1)
            local xb = make("Frame", {
                BackgroundColor3 = C.Dim, BorderSizePixel = 0,
                AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(11, 2), Rotation = -45
            }, delBtn)
            corner(xb, 1)
            delBtn.MouseEnter:Connect(function()
                tween(xa, 0.12, {BackgroundColor3 = C.Danger})
                tween(xb, 0.12, {BackgroundColor3 = C.Danger})
            end)
            delBtn.MouseLeave:Connect(function()
                tween(xa, 0.12, {BackgroundColor3 = C.Dim})
                tween(xb, 0.12, {BackgroundColor3 = C.Dim})
            end)
            delBtn.MouseButton1Click:Connect(function() deleteProfile(n) end)
        end
    end

    saveBtn.MouseButton1Click:Connect(function() saveProfile(nameBox.Text) end)
    nameBox.FocusLost:Connect(function(enter)
        tween(nameStroke, 0.15, {Transparency = 1})
        if enter then saveProfile(nameBox.Text) end
    end)

    G.createToggle(pc, "set.autosave", autosaveEnabled, G.menuLabels, function(v)
        autosaveEnabled = v
        G.StoreData.autosaveEnabled = v
        G.writeStore()
    end)

    -- الخط
    local fontCard = G.newCard(gr, "set.font", G.menuLabels)
    local fontItems = {}
    for _, f in ipairs(G.FontList) do fontItems[#fontItems + 1] = {id = f.id, text = f.id} end
    local refreshFontPills = G.createPills(fontCard, fontItems, function() return G.currentFontId end, function(id)
        G.setFont(id, true)
    end, G.menuLabels)

    table.insert(G.langListeners, function()
        task.defer(function()
            refreshLangPills()
            refreshFontPills()
        end)
    end)
    table.insert(G.postApplyHooks, function()
        refreshLangPills()
        refreshFontPills()
        nameSlider.set(G.TextCfg.pname.size, true)
    end)

    ------------------------------------------------------------------
    -- تبويب Appearance
    ------------------------------------------------------------------
    local al = newTab("appearance")
    local ac = G.newCard(al, "app.title", G.menuLabels)

    G.applyAppearance = function()
        MainFrame.BackgroundColor3 = G.BgColors[G.AppCfg.bgColorIndex] or G.BgColors[1]
        MainFrame.BackgroundTransparency = 1 - G.AppCfg.bgOpacity / 100
        if G.AppCfg.imageId ~= "" then
            G.BgImage.Image = "rbxassetid://" .. G.AppCfg.imageId
            G.BgImage.ImageTransparency = 1 - G.AppCfg.imageOpacity / 100
            G.BgImage.Visible = true
        else
            G.BgImage.Visible = false
            G.BgImage.Image = ""
        end
        if G.menuVisible then G.MainScale.Scale = G.AppCfg.scale / 100 end
    end

    G.createSlider(ac, "app.scale", 60, 130, 100, function(v)
        G.AppCfg.scale = v
        G.applyAppearance()
    end, "App.scale", G.menuLabels)
    G.createSlider(ac, "app.bgOpacity", 0, 100, 100, function(v)
        G.AppCfg.bgOpacity = v
        G.applyAppearance()
    end, "App.bgOpacity", G.menuLabels)

    local bgLbl = make("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 22),
        Font = Enum.Font.GothamBold,
        Text = "",
        TextColor3 = Color3.fromRGB(240, 240, 255),
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = ord(ac)
    }, ac)
    bind(bgLbl, "app.bgColor")
    G.autoLabel(bgLbl, G.menuLabels, G.groupSize(G.menuLabels))
    make("UIPadding", {PaddingLeft = UDim.new(0, 6)}, bgLbl)

    local swRow = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 36),
        LayoutOrder = ord(ac)
    }, ac)
    make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, swRow)
    make("UIPadding", {PaddingLeft = UDim.new(0, 6)}, swRow)

    local bgSwatches = {}
    local function selectBg(idx)
        for j, s in ipairs(bgSwatches) do
            tween(s, 0.15, {Transparency = (j == idx) and 0 or 1})
        end
    end
    for i, bc in ipairs(G.BgColors) do
        local b = make("TextButton", {
            BackgroundColor3 = bc,
            AutoButtonColor = false,
            Size = UDim2.fromOffset(34, 28),
            Text = "",
            LayoutOrder = i
        }, swRow)
        corner(b, 6)
        make("UIStroke", {Color = C.BoxBorder, Thickness = 1}, b)
        bgSwatches[i] = make("UIStroke", {
            Color = C.White, Thickness = 2, Transparency = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        }, b)
        b.MouseButton1Click:Connect(function()
            G.AppCfg.bgColorIndex = i
            selectBg(i)
            G.applyAppearance()
            G.markDirty()
        end)
    end
    selectBg(G.AppCfg.bgColorIndex)
    G.registerControl("App.bgColor", function() return G.AppCfg.bgColorIndex end, function(v)
        if type(v) == "number" and G.BgColors[v] then
            G.AppCfg.bgColorIndex = v
            selectBg(v)
            G.applyAppearance()
        end
    end)

    local imgLbl = make("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 22),
        Font = Enum.Font.GothamBold,
        Text = "",
        TextColor3 = Color3.fromRGB(240, 240, 255),
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = ord(ac)
    }, ac)
    bind(imgLbl, "app.bgImage")
    G.autoLabel(imgLbl, G.menuLabels, G.groupSize(G.menuLabels))
    make("UIPadding", {PaddingLeft = UDim.new(0, 6)}, imgLbl)

    local imgBox = make("TextBox", {
        BackgroundColor3 = C.Row,
        Size = UDim2.new(1, 0, 0, 34),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Enum.Font.GothamBold,
        Text = "",
        PlaceholderText = "rbxassetid",
        PlaceholderColor3 = C.Dim,
        TextColor3 = C.Text,
        TextSize = G.groupSize(G.menuLabels),
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = ord(ac)
    }, ac)
    corner(imgBox, 6)
    make("UIPadding", {
        PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
        PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4)
    }, imgBox)
    table.insert(G.menuLabels, imgBox)

    local function setImageId(text)
        local id = string.match(tostring(text or ""), "%d+") or ""
        G.AppCfg.imageId = id
        imgBox.Text = id
        G.applyAppearance()
    end
    imgBox.FocusLost:Connect(function()
        setImageId(imgBox.Text)
        G.markDirty()
    end)
    G.registerControl("App.imageId", function() return G.AppCfg.imageId end, function(v)
        setImageId(v)
    end)

    G.createSlider(ac, "app.imgOpacity", 0, 100, 35, function(v)
        G.AppCfg.imageOpacity = v
        G.applyAppearance()
    end, "App.imgOpacity", G.menuLabels)

    G.createButton(ac, "app.reset", G.menuLabels, function()
        G.controls["App.scale"].set(100)
        G.controls["App.bgOpacity"].set(100)
        G.controls["App.bgColor"].set(1)
        G.controls["App.imageId"].set("")
        G.controls["App.imgOpacity"].set(35)
        G.markDirty()
    end, true)

    ------------------------------------------------------------------
    -- تبويب ESP Text (مكان النصوص + معاينة)
    ------------------------------------------------------------------
    local tl, tr = newTab("text")
    local selEl = "pname"

    local elCard = G.newCard(tl, "txt.title", G.menuLabels)
    local elItems = {
        {id = "pname", key = "txt.pname"}, {id = "pdist", key = "txt.pdist"},
        {id = "oname", key = "txt.oname"}, {id = "odist", key = "txt.odist"}
    }
    local refreshElPills = G.createPills(elCard, elItems, function() return selEl end, function(id)
        selEl = id
        refreshEditor()
    end, G.menuLabels)

    local pvTitle = make("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 22),
        Font = Enum.Font.GothamBold,
        Text = "",
        TextColor3 = C.Dim,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = ord(elCard)
    }, elCard)
    bind(pvTitle, "txt.preview")
    G.autoLabel(pvTitle, G.menuLabels, G.groupSize(G.menuLabels))
    make("UIPadding", {PaddingLeft = UDim.new(0, 6)}, pvTitle)

    local stage = make("Frame", {
        BackgroundColor3 = Color3.fromRGB(12, 12, 16),
        Size = UDim2.new(1, 0, 0, 190),
        ClipsDescendants = true,
        LayoutOrder = ord(elCard)
    }, elCard)
    corner(stage, 8)
    make("UIStroke", {Color = C.BoxBorder, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, stage)

    local dummy = make("Frame", {
        BackgroundColor3 = Color3.fromRGB(58, 58, 72),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5)
    }, stage)
    corner(dummy, 6)

    local markers = {}
    for i = 1, 3 do
        local m = make("Frame", {
            BackgroundColor3 = C.Accent,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromOffset(5, 5)
        }, stage)
        corner(m, 3)
        markers[i] = m
    end

    -- نصوص المعاينة (ما تُسجَّل في الخطوط العامة عشان تحتفظ بخط اللعبة)
    local function previewLabel()
        local l = make("TextLabel", {
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.XY,
            Size = UDim2.fromOffset(0, 0),
            Font = Enum.Font.GothamBold,
            Text = "",
            TextColor3 = C.White,
            TextWrapped = false,
            TextTruncate = Enum.TextTruncate.None
        }, nil)
        l.Parent = stage
        return l
    end
    local pvName, pvDist = previewLabel(), previewLabel()

    local function refreshPreview()
        local isP = (selEl == "pname" or selEl == "pdist")
        local nameCfg = G.TextCfg[isP and "pname" or "oname"]
        local distCfg = G.TextCfg[isP and "pdist" or "odist"]
        local w = stage.AbsoluteSize.X / G.uiScaleFactor()
        if w <= 0 then w = 250 end
        local cx = w / 2

        local topY, botY
        if isP then
            dummy.Size = UDim2.fromOffset(34, 84)
            topY, botY = 58, 142
        else
            dummy.Size = UDim2.fromOffset(96, 64)
            topY, botY = 68, 132
        end
        dummy.Position = UDim2.fromOffset(cx, 100)
        local anchors = {top = Vector2.new(cx, topY), center = Vector2.new(cx, 100), bottom = Vector2.new(cx, botY)}
        markers[1].Position = UDim2.fromOffset(cx, topY)
        markers[2].Position = UDim2.fromOffset(cx, 100)
        markers[3].Position = UDim2.fromOffset(cx, botY)

        local nm = isP and "PlayerName" or T("obj.Generator")
        if nameCfg.spaced and G.currentLang ~= "ar" then nm = G.spaceText(nm) end
        pvName.Text = nm
        pvName.TextColor3 = isP and _G.Survivor_Color or G.ObjState.color.Generator
        pvDist.Text = G.fmtDist(distCfg.format or 1, 53)
        pvDist.TextColor3 = isP and _G.Survivor_DistanceColor or C.White

        G.styleLabel(pvName, nameCfg)
        G.placeLabel(pvName, nameCfg, anchors)
        G.styleLabel(pvDist, distCfg)
        G.placeLabel(pvDist, distCfg, anchors)

        -- النص المحدد واضح، والثاني أخفّ شوي
        local selIsName = (selEl == "pname" or selEl == "oname")
        pvName.TextTransparency = math.clamp(G.labelMeta[pvName].baseT + (selIsName and 0 or 0.45), 0, 0.9)
        pvDist.TextTransparency = math.clamp(G.labelMeta[pvDist].baseT + (selIsName and 0.45 or 0), 0, 0.9)
    end
    track(stage:GetPropertyChangedSignal("AbsoluteSize"):Connect(refreshPreview))

    -- عناصر التحكم (تطبّق على النص المحدد)
    local cc = G.newCard(tr, "txt.controls", G.menuLabels)
    local ed = {}
    local function cfg() return G.TextCfg[selEl] end
    local function changed()
        G.bumpStyle()
        refreshPreview()
        G.markDirty()
    end

    local function subLabel(key)
        local l = make("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 22),
            Font = Enum.Font.GothamBold,
            Text = "",
            TextColor3 = Color3.fromRGB(240, 240, 255),
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = ord(cc)
        }, cc)
        bind(l, key)
        G.autoLabel(l, G.menuLabels, G.groupSize(G.menuLabels))
        make("UIPadding", {PaddingLeft = UDim.new(0, 6)}, l)
        return l
    end

    subLabel("txt.pos")
    local posItems = {{id = "above", key = "txt.above"}, {id = "center", key = "txt.center"}, {id = "below", key = "txt.below"}}
    local refreshPosPills = G.createPills(cc, posItems, function() return cfg().pos end, function(id)
        cfg().pos = id
        changed()
    end, G.menuLabels, 3)

    ed.ox = G.createSlider(cc, "txt.ox", -200, 200, 0, function(v) cfg().ox = v; changed() end, nil, G.menuLabels)
    ed.oy = G.createSlider(cc, "txt.oy", -200, 200, 0, function(v) cfg().oy = v; changed() end, nil, G.menuLabels)
    ed.size = G.createSlider(cc, "txt.size", 8, 60, 14, function(v)
        cfg().size = v
        changed()
        nameSlider.set(G.TextCfg.pname.size, true)
    end, nil, G.menuLabels)
    ed.outline = G.createSlider(cc, "txt.outline", 0, 100, 75, function(v) cfg().outline = v; changed() end, nil, G.menuLabels)
    ed.opacity = G.createSlider(cc, "txt.opacity", 20, 100, 100, function(v) cfg().opacity = v; changed() end, nil, G.menuLabels)

    local _, _, boldApi = G.createToggle(cc, "txt.bold", true, G.menuLabels, function(v) cfg().bold = v; changed() end)
    local _, _, spacedApi = G.createToggle(cc, "txt.spaced", false, G.menuLabels, function(v) cfg().spaced = v; changed() end)
    ed.bold, ed.spaced = boldApi, spacedApi

    local fmtHolder = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = ord(cc)
    }, cc)
    make("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, fmtHolder)
    do
        local l = make("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 22),
            Font = Enum.Font.GothamBold,
            Text = "",
            TextColor3 = Color3.fromRGB(240, 240, 255),
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 1
        }, fmtHolder)
        bind(l, "txt.format")
        G.autoLabel(l, G.menuLabels, G.groupSize(G.menuLabels))
        make("UIPadding", {PaddingLeft = UDim.new(0, 6)}, l)
    end
    local fmtItems = {}
    for i = 1, #G.DistFormats do
        fmtItems[#fmtItems + 1] = {id = i, text = string.format(G.DistFormats[i], 53)}
    end
    local refreshFmtPills = G.createPills(fmtHolder, fmtItems, function() return cfg().format end, function(id)
        cfg().format = id
        changed()
    end, G.menuLabels)

    G.createButton(cc, "txt.reset", G.menuLabels, function()
        local d = G.TextDefaults[selEl]
        for k, v in pairs(d) do G.TextCfg[selEl][k] = v end
        G.bumpStyle()
        refreshEditor()
        G.markDirty()
    end, true)

    refreshEditor = function()
        local c = cfg()
        refreshElPills()
        refreshPosPills()
        ed.ox.set(c.ox, true)
        ed.oy.set(c.oy, true)
        ed.size.set(c.size, true)
        ed.outline.set(c.outline, true)
        ed.opacity.set(c.opacity, true)
        ed.bold.set(c.bold, true)
        ed.spaced.set(c.spaced, true)
        fmtHolder.Visible = (c.format ~= nil)
        if c.format then refreshFmtPills() end
        nameSlider.set(G.TextCfg.pname.size, true)
        refreshPreview()
    end

    -- حفظ إعدادات كل نص
    for _, el in ipairs(G.TextOrder) do
        for prop, default in pairs(G.TextDefaults[el]) do
            G.registerControl("Text." .. el .. "." .. prop, function() return G.TextCfg[el][prop] end, function(v)
                if type(v) == type(default) then
                    if prop == "pos" and not G.ANCHORS[v] then return end
                    G.TextCfg[el][prop] = v
                    G.bumpStyle()
                end
            end)
        end
    end
    table.insert(G.postApplyHooks, function() refreshEditor() end)
    table.insert(G.langListeners, function() refreshPreview() end)

    ------------------------------------------------------------------
    -- تبويب World (إضاءة وأجواء)
    ------------------------------------------------------------------
    local wl, wr = newTab("world")
    local LU = {}
    local lc = G.newCard(wl, "world.title", G.menuLabels)

    local _, _, enApi = G.createToggle(lc, "world.enable", false, G.menuLabels, function(v)
        G.LightCfg.enabled = v
    end, "World.enabled")
    LU.enable = enApi

    local Presets = {
        fullbright = {brightness = 3, exposure = 0.4, ambient = 200, time = 14, fogAmount = 0, shadows = false, effects = false, snow = false, snowAmount = 50, tint = Color3.fromRGB(255, 255, 255), fogColor = Color3.fromRGB(190, 190, 195)},
        day = {brightness = 2.5, exposure = 0.2, ambient = 140, time = 14, fogAmount = 0, shadows = true, effects = true, snow = false, snowAmount = 50, tint = Color3.fromRGB(255, 255, 255), fogColor = Color3.fromRGB(190, 190, 195)},
        sunset = {brightness = 2, exposure = 0, ambient = 120, time = 17.8, fogAmount = 40, shadows = true, effects = true, snow = false, snowAmount = 50, tint = Color3.fromRGB(255, 215, 175), fogColor = Color3.fromRGB(255, 170, 120)},
        night = {brightness = 1.5, exposure = 0.8, ambient = 110, time = 0, fogAmount = 0, shadows = true, effects = true, snow = false, snowAmount = 50, tint = Color3.fromRGB(200, 215, 255), fogColor = Color3.fromRGB(120, 130, 160)},
        fog = {brightness = 2, exposure = 0.2, ambient = 130, time = 13, fogAmount = 78, shadows = true, effects = true, snow = false, snowAmount = 50, tint = Color3.fromRGB(255, 255, 255), fogColor = Color3.fromRGB(190, 190, 200)},
        winter = {brightness = 2.2, exposure = 0.3, ambient = 150, time = 12, fogAmount = 62, shadows = true, effects = true, snow = true, snowAmount = 60, tint = Color3.fromRGB(205, 222, 255), fogColor = Color3.fromRGB(210, 225, 245)}
    }

    local syncLightUI
    local function applyPreset(id)
        local p = Presets[id]
        if not p then return end
        for k, v in pairs(p) do G.LightCfg[k] = v end
        G.LightCfg.enabled = true
        syncLightUI()
        G.markDirty()
    end

    local presetItems = {
        {id = "fullbright", key = "world.p.fullbright"}, {id = "day", key = "world.p.day"},
        {id = "sunset", key = "world.p.sunset"}, {id = "night", key = "world.p.night"},
        {id = "fog", key = "world.p.fog"}, {id = "winter", key = "world.p.winter"}
    }
    local presetsLbl = make("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 22),
        Font = Enum.Font.GothamBold,
        Text = "",
        TextColor3 = C.Dim,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = ord(lc)
    }, lc)
    bind(presetsLbl, "world.presets")
    G.autoLabel(presetsLbl, G.menuLabels, G.groupSize(G.menuLabels))
    make("UIPadding", {PaddingLeft = UDim.new(0, 6)}, presetsLbl)
    G.createPills(lc, presetItems, function() return nil end, function(id) applyPreset(id) end, G.menuLabels)

    G.createButton(lc, "world.restore", G.menuLabels, function()
        G.LightCfg.enabled = false
        LU.enable.set(false, true)
        G.markDirty()
    end, true)

    LU.brightness = G.createSlider(lc, "world.brightness", 0, 60, 20, function(v) G.LightCfg.brightness = v / 10 end,
        "World.brightness", G.menuLabels, function(v) return string.format("%.1f", v / 10) end)
    LU.exposure = G.createSlider(lc, "world.exposure", -30, 30, 0, function(v) G.LightCfg.exposure = v / 10 end,
        "World.exposure", G.menuLabels, function(v) return string.format("%.1f", v / 10) end)
    LU.ambient = G.createSlider(lc, "world.ambient", 0, 255, 110, function(v) G.LightCfg.ambient = v end,
        "World.ambient", G.menuLabels)
    LU.time = G.createSlider(lc, "world.time", 0, 240, 140, function(v) G.LightCfg.time = v / 10 end,
        "World.time", G.menuLabels, function(v) return string.format("%.1f", v / 10) end)
    LU.fog = G.createSlider(lc, "world.fog", 0, 100, 0, function(v) G.LightCfg.fogAmount = v end,
        "World.fog", G.menuLabels)

    local oc = G.newCard(wr, "world.options", G.menuLabels)
    local _, _, shApi = G.createToggle(oc, "world.shadows", true, G.menuLabels, function(v) G.LightCfg.shadows = v end, "World.shadows")
    local _, _, efApi = G.createToggle(oc, "world.effects", true, G.menuLabels, function(v) G.LightCfg.effects = v end, "World.effects")
    local _, _, snApi = G.createToggle(oc, "world.snow", false, G.menuLabels, function(v) G.LightCfg.snow = v end, "World.snow")
    LU.shadows, LU.effects, LU.snow = shApi, efApi, snApi
    LU.snowAmount = G.createSlider(oc, "world.snowAmount", 5, 100, 50, function(v) G.LightCfg.snowAmount = v end,
        "World.snowAmount", G.menuLabels)

    G.registerControl("World.tint", function() return G.LightCfg.tint end, function(v)
        local c = G.toColor(v)
        if c then G.LightCfg.tint = c end
    end)
    G.registerControl("World.fogColor", function() return G.LightCfg.fogColor end, function(v)
        local c = G.toColor(v)
        if c then G.LightCfg.fogColor = c end
    end)

    syncLightUI = function()
        LU.enable.set(G.LightCfg.enabled, true)
        LU.brightness.set(G.LightCfg.brightness * 10, true)
        LU.exposure.set(G.LightCfg.exposure * 10, true)
        LU.ambient.set(G.LightCfg.ambient, true)
        LU.time.set(G.LightCfg.time * 10, true)
        LU.fog.set(G.LightCfg.fogAmount, true)
        LU.shadows.set(G.LightCfg.shadows, true)
        LU.effects.set(G.LightCfg.effects, true)
        LU.snow.set(G.LightCfg.snow, true)
        LU.snowAmount.set(G.LightCfg.snowAmount, true)
    end
    table.insert(G.postApplyHooks, syncLightUI)

    ------------------------------------------------------------------
    -- تبويب Camera (FOV + منظور أول شخص + FPS)
    ------------------------------------------------------------------
    local cl, cr = newTab("camera")
    local cc2 = G.newCard(cl, "cam.title", G.menuLabels)

    local _, _, camEnApi = G.createToggle(cc2, "cam.enable", false, G.menuLabels, function(v)
        G.CameraCfg.enabled = v
    end, "Cam.enabled")

    local fovApi = G.createSlider(cc2, "cam.fov", 50, 120, 70, function(v)
        G.CameraCfg.fov = v
    end, "Cam.fov", G.menuLabels)

    local _, _, fpApi = G.createToggle(cc2, "cam.firstPerson", false, G.menuLabels, function(v)
        G.CameraCfg.firstPerson = v
    end, "Cam.firstPerson")

    local _, _, zoomEnApi = G.createToggle(cc2, "cam.zoomEnable", false, G.menuLabels, function(v)
        G.CameraCfg.zoomEnabled = v
    end, "Cam.zoomEnabled")

    local zoomMinApi = G.createSlider(cc2, "cam.zoomMin", 0, 30, 1, function(v)
        G.CameraCfg.zoomMin = v / 2
    end, "Cam.zoomMin", G.menuLabels, function(v) return string.format("%.1f", v / 2) end)

    local zoomMaxApi = G.createSlider(cc2, "cam.zoomMax", 10, 400, 128, function(v)
        G.CameraCfg.zoomMax = v
    end, "Cam.zoomMax", G.menuLabels)

    G.createButton(cc2, "cam.reset", G.menuLabels, function()
        G.controls["Cam.enabled"].set(false)
        G.controls["Cam.fov"].set(70)
        G.controls["Cam.firstPerson"].set(false)
        G.controls["Cam.zoomEnabled"].set(false)
        G.controls["Cam.zoomMin"].set(1)
        G.controls["Cam.zoomMax"].set(128)
        G.markDirty()
    end, true)

    local cc3 = G.newCard(cr, "cam.fps", G.menuLabels)
    local _, _, fpsApi = G.createToggle(cc3, "opt.enabled", false, G.menuLabels, function(v)
        G.CameraCfg.showFps = v
    end, "Cam.showFps")
    local fpsSizeApi = G.createSlider(cc3, "cam.fpsSize", 10, 30, 14, function(v)
        G.CameraCfg.fpsSize = v
    end, "Cam.fpsSize", G.menuLabels)

    table.insert(G.postApplyHooks, function()
        camEnApi.set(G.CameraCfg.enabled, true)
        fovApi.set(G.CameraCfg.fov, true)
        fpApi.set(G.CameraCfg.firstPerson, true)
        zoomEnApi.set(G.CameraCfg.zoomEnabled, true)
        zoomMinApi.set(G.CameraCfg.zoomMin * 2, true)
        zoomMaxApi.set(G.CameraCfg.zoomMax, true)
        fpsApi.set(G.CameraCfg.showFps, true)
        fpsSizeApi.set(G.CameraCfg.fpsSize, true)
    end)

    ------------------------------------------------------------------
    -- تبديل التبويبات
    ------------------------------------------------------------------
    switchTab = function(id)
        if id == currentTab or not tabFrames[id] then return end
        local old, new = tabFrames[currentTab], tabFrames[id]
        currentTab = id
        old.Visible = false
        new.GroupTransparency = 1
        new.Visible = true
        tween(new, 0.25, {GroupTransparency = 0})
        if id == "text" then refreshEditor() end
    end

    refreshEditor()
end

G.buildSettings()

---------------------------------------------------------------------
-- طبقة النصوص فوق الشاشة (Overlay): كل نصوص اللاعبين والأغراض
---------------------------------------------------------------------
G.Overlay = make("ScreenGui", {
    Name = "CleanESPOverlay",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 1,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
})
if not pcall(function() G.Overlay.Parent = CoreGui end) then
    G.Overlay.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

G.STUD_TO_METER = 0.28
G.playerCat = {}        -- [player] = "Killer" / "Survivor"
G.playerEligible = {}   -- [player] = true إذا داخل المباراة وضمن النطاق
G.pstate = {}           -- [player] = حالة نصوص اللاعب
G.ostate = {}           -- [entry] = حالة نصوص الغرض

function G.newOverlayLabel()
    local l = make("TextLabel", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.fromOffset(0, 0),
        Font = Enum.Font.GothamBold,
        Text = "",
        TextColor3 = C.White,
        TextSize = 14,
        TextWrapped = false,
        TextTruncate = Enum.TextTruncate.None,
        Visible = false
    }, G.Overlay)
    G.labelMeta[l] = {ver = -1, text = "", baseT = 0}
    return l
end

function G.setText(lbl, txt)
    local m = G.labelMeta[lbl]
    if m.text ~= txt then
        m.text = txt
        lbl.Text = txt
    end
end

function G.ensureStyle(lbl, cfg)
    if G.labelMeta[lbl].ver ~= G.styleVersion then G.styleLabel(lbl, cfg) end
end

function G.destroyLabel(lbl)
    if lbl then
        G.labelMeta[lbl] = nil
        lbl:Destroy()
    end
end

function G.clearPlayerState(plr)
    local st = G.pstate[plr]
    if st then
        G.destroyLabel(st.nameLbl)
        G.destroyLabel(st.distLbl)
        G.pstate[plr] = nil
    end
end

function G.clearObjectState(e)
    local st = G.ostate[e]
    if st then
        G.destroyLabel(st.nameLbl)
        G.destroyLabel(st.distLbl)
        G.ostate[e] = nil
    end
end

function G.isKiller(plr)
    if string.find(string.lower(plr.Name), "killer") then return true end
    if plr.Team and string.find(string.lower(plr.Team.Name), "killer") then return true end
    return false
end

-- هل اللاعب داخل المباراة؟ (حي، مو في اللوبي، مو متفرج)
G.OUT_WORDS = {"lobby", "spectat", "dead", "waiting"}

function G.isInMatch(plr, char)
    if not char or not char:IsDescendantOf(workspace) then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return false end

    if plr.Team then
        local tn = string.lower(plr.Team.Name)
        for _, w in ipairs(G.OUT_WORDS) do
            if string.find(tn, w, 1, true) then return false end
        end
    end

    for name, v in pairs(plr:GetAttributes()) do
        local n = string.lower(name)
        if v == true and (string.find(n, "lobby", 1, true) or string.find(n, "dead", 1, true) or string.find(n, "spectat", 1, true)) then
            return false
        end
        if v == false and string.find(n, "alive", 1, true) then return false end
    end
    return true
end

-- فحص الرؤية: نطلق أشعة من الكاميرا على الرأس والصدر والرجل
G.rayParams = RaycastParams.new()
G.rayParams.FilterType = Enum.RaycastFilterType.Exclude
pcall(function() G.rayParams.RespectCanCollide = true end)

function G.isVisible(cam, char)
    local origin = cam.CFrame.Position
    local filter = {char}
    if LocalPlayer.Character then table.insert(filter, LocalPlayer.Character) end
    G.rayParams.FilterDescendantsInstances = filter

    local points = {
        char:FindFirstChild("Head"),
        char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart"),
        char:FindFirstChild("LowerTorso") or char:FindFirstChild("Left Leg") or char:FindFirstChild("LeftFoot")
    }
    for _, part in pairs(points) do
        if part then
            if not workspace:Raycast(origin, part.Position - origin, G.rayParams) then
                return true
            end
        end
    end
    return false
end

-- إذا ما نحتاج الهايلايت نحذفه بالكامل (ما نخلي أي أثر)
function G.updateHighlight(char, want, col, visible)
    local hl = char:FindFirstChild("Fast_ESP_HL")
    if want then
        local fillT = visible and 0.88 or 0.35
        local outT = visible and 0.6 or 0
        if not hl then
            hl = make("Highlight", {
                Name = "Fast_ESP_HL",
                Adornee = char,
                DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
                FillTransparency = fillT,
                OutlineTransparency = outT
            }, char)
            hl:SetAttribute("vis", visible)
        end
        hl.Enabled = true
        hl.FillColor = col
        hl.OutlineColor = col
        if hl:GetAttribute("vis") ~= visible then
            hl:SetAttribute("vis", visible)
            tween(hl, 0.15, {FillTransparency = fillT, OutlineTransparency = outT})
        end
    elseif hl then
        hl:Destroy()
    end
end

---------------------------------------------------------------------
-- اللاعبين: حلقة بطيئة (0.1 ثانية) تحدّث النصوص والهايلايت
---------------------------------------------------------------------
local acc = 0
track(RunService.Heartbeat:Connect(function(dt)
    acc += dt
    if acc < 0.1 then return end
    acc = 0
    pcall(function()
        local cam = workspace.CurrentCamera
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local from = myRoot and myRoot.Position or cam.CFrame.Position
        local rangeStuds = _G.MenuSettings.PlayerRange / G.STUD_TO_METER

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local cat = G.isKiller(plr) and "Killer" or "Survivor"
                G.playerCat[plr] = cat

                local char = plr.Character
                local head = char and char:FindFirstChild("Head")
                local dist = math.huge
                local eligible = false
                if head and G.isInMatch(plr, char) then
                    dist = (head.Position - from).Magnitude
                    eligible = dist <= rangeStuds
                end
                G.playerEligible[plr] = eligible

                local on = eligible and _G[cat .. "_Enabled"]
                local showName = on and _G[cat .. "_Name"]
                local showDist = on and _G[cat .. "_Distance"]
                local showHL = on and _G[cat .. "_Highlight"]

                if (showName or showDist) and head then
                    local st = G.pstate[plr]
                    if not st then
                        st = {}
                        G.pstate[plr] = st
                    end
                    st.head = head
                    st.root = char:FindFirstChild("HumanoidRootPart") or head

                    if showName then
                        if not st.nameLbl then st.nameLbl = G.newOverlayLabel() end
                        local txt = plr.Name
                        if G.TextCfg.pname.spaced then txt = G.spaceText(txt) end
                        G.setText(st.nameLbl, txt)
                        st.nameLbl.TextColor3 = _G[cat .. "_Color"]
                        G.ensureStyle(st.nameLbl, G.TextCfg.pname)
                    elseif st.nameLbl then
                        G.destroyLabel(st.nameLbl)
                        st.nameLbl = nil
                    end

                    if showDist then
                        if not st.distLbl then st.distLbl = G.newOverlayLabel() end
                        G.setText(st.distLbl, G.fmtDist(G.TextCfg.pdist.format, math.floor(dist * G.STUD_TO_METER)))
                        st.distLbl.TextColor3 = _G[cat .. "_DistanceColor"]
                        G.ensureStyle(st.distLbl, G.TextCfg.pdist)
                    elseif st.distLbl then
                        G.destroyLabel(st.distLbl)
                        st.distLbl = nil
                    end
                else
                    G.clearPlayerState(plr)
                end

                if char then
                    local visible = false
                    if showHL then visible = G.isVisible(cam, char) end
                    G.updateHighlight(char, showHL, _G[cat .. "_HighlightColor"], visible)
                end
            end
        end
    end)
end))

---------------------------------------------------------------------
-- الهيكل العظمي (Drawing): كل فريم فقط إذا كان مفعّل
---------------------------------------------------------------------
G.R15Bones = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
}
G.R6Bones = {
    {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
    {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
}

G.skeletons = {}

function G.removeSkeleton(plr)
    local sk = G.skeletons[plr]
    if sk then
        for _, l in ipairs(sk.lines) do
            if not pcall(function() l:Remove() end) then
                pcall(function() l:Destroy() end)
            end
        end
        G.skeletons[plr] = nil
    end
end

if hasDrawing then
    track(RunService.RenderStepped:Connect(function()
        local anyOn = (_G.Survivor_Enabled and _G.Survivor_Skeleton) or (_G.Killer_Enabled and _G.Killer_Skeleton)
        if not anyOn then
            if next(G.skeletons) ~= nil then
                for plr in pairs(G.skeletons) do G.removeSkeleton(plr) end
            end
            return
        end

        pcall(function()
            local cam = workspace.CurrentCamera
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then
                    local cat = G.playerCat[plr] or "Survivor"
                    local char = plr.Character
                    local want = char and G.playerEligible[plr] and _G[cat .. "_Enabled"] and _G[cat .. "_Skeleton"]
                    local sk = G.skeletons[plr]

                    if want then
                        if not sk then
                            sk = {lines = {}}
                            G.skeletons[plr] = sk
                        end
                        local bones = char:FindFirstChild("UpperTorso") and G.R15Bones or G.R6Bones
                        local col = _G[cat .. "_SkeletonColor"]

                        for i, b in ipairs(bones) do
                            local line = sk.lines[i]
                            if not line then
                                line = Drawing.new("Line")
                                line.Thickness = 1.5
                                line.Transparency = 1
                                sk.lines[i] = line
                            end
                            local pa, pb = char:FindFirstChild(b[1]), char:FindFirstChild(b[2])
                            if pa and pb then
                                local va = cam:WorldToViewportPoint(pa.Position)
                                local vb = cam:WorldToViewportPoint(pb.Position)
                                if va.Z > 0 and vb.Z > 0 then
                                    line.From = Vector2.new(va.X, va.Y)
                                    line.To = Vector2.new(vb.X, vb.Y)
                                    line.Color = col
                                    line.Visible = true
                                else
                                    line.Visible = false
                                end
                            else
                                line.Visible = false
                            end
                        end
                        for i = #bones + 1, #sk.lines do sk.lines[i].Visible = false end
                    elseif sk then
                        G.removeSkeleton(plr)
                    end
                end
            end
        end)
    end))
end

track(Players.PlayerRemoving:Connect(function(plr)
    G.removeSkeleton(plr)
    G.clearPlayerState(plr)
    G.playerCat[plr] = nil
    G.playerEligible[plr] = nil
end))

---------------------------------------------------------------------
-- الأغراض: البحث بالاسم داخل workspace
-- إذا اللعبة تسمّي الأغراض بأسماء ثانية عدّل الكلمات في ObjectTypes
---------------------------------------------------------------------
G.objLookup = {}

function G.normName(n)
    return (string.gsub(string.lower(n), "[%s_%-%.]", ""))
end

G.objPriority = {
    "BreakableWall", "CenobiteBox", "ConjoinedTwin", "EscapeDoor", "MeatHook",
    "Generator", "Pallet", "Window", "Totem", "Hatch", "Breakable", "Locker",
    "Traps", "Zombie", "Drone", "Item", "Guard", "Dog"
}

function G.classifyObject(name)
    local n = G.normName(name)
    if n == "" then return nil end
    for _, key in ipairs(G.objPriority) do
        local ot = G.objByKey[key]
        if ot.exact then
            for _, w in ipairs(ot.exact) do
                if n == w then return ot end
            end
        end
        if ot.contains then
            for _, w in ipairs(ot.contains) do
                if string.find(n, w, 1, true) then return ot end
            end
        end
    end
    return nil
end

function G.registerObject(inst)
    if G.objLookup[inst] then return end
    if not (inst:IsA("Model") or inst:IsA("BasePart")) then return end
    local ot = G.classifyObject(inst.Name)
    if not ot then return end

    local p = inst.Parent
    while p and p ~= workspace do
        if G.objLookup[p] then return end
        p = p.Parent
    end
    if inst:IsA("Model") and Players:GetPlayerFromCharacter(inst) then return end
    local m = inst:FindFirstAncestorOfClass("Model")
    if m and Players:GetPlayerFromCharacter(m) then return end

    local e = {inst = inst, ot = ot}
    G.objLookup[inst] = e
    G.ObjEntries[ot.key][inst] = e
end

function G.removeObject(inst)
    local e = G.objLookup[inst]
    if e then
        G.clearObjectState(e)
        G.ObjEntries[e.ot.key][inst] = nil
        G.objLookup[inst] = nil
    end
end

task.spawn(function()
    local list = workspace:GetDescendants()
    for i, inst in ipairs(list) do
        pcall(G.registerObject, inst)
        if i % 1500 == 0 then task.wait() end
    end
end)
track(workspace.DescendantAdded:Connect(function(inst) pcall(G.registerObject, inst) end))
track(workspace.DescendantRemoving:Connect(function(inst) pcall(G.removeObject, inst) end))

-- نثبّت النص على أكبر قطعة في الغرض (الأقل حركة) بدل أول قطعة
function G.pickAnchor(inst)
    if inst:IsA("BasePart") then return inst end
    local best, bestVol, count = nil, -1, 0
    for _, d in ipairs(inst:GetDescendants()) do
        if d:IsA("BasePart") then
            local s = d.Size
            local vol = s.X * s.Y * s.Z
            if vol > bestVol then best, bestVol = d, vol end
            count += 1
            if count >= 80 then break end
        end
    end
    return best
end

-- حلقة بطيئة (0.25 ثانية): نختار الأقرب ضمن النطاق ونجهّز نصوصه
G.objAcc = 0
track(RunService.Heartbeat:Connect(function(dt)
    G.objAcc += dt
    if G.objAcc < 0.25 then return end
    G.objAcc = 0
    pcall(function()
        local cam = workspace.CurrentCamera
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local from = myRoot and myRoot.Position or cam.CFrame.Position
        local range = G.ObjState.range

        local cands = {}
        for _, ot in ipairs(G.ObjectTypes) do
            if G.ObjState.on[ot.key] then
                for inst, e in pairs(G.ObjEntries[ot.key]) do
                    if not inst.Parent then
                        G.removeObject(inst)
                    else
                        local part = e.part
                        if not part or not part.Parent then
                            part = G.pickAnchor(inst)
                            e.part = part
                        end
                        if part then
                            local d = (part.Position - from).Magnitude * G.STUD_TO_METER
                            if d <= range then
                                cands[#cands + 1] = {e = e, d = d, ot = ot}
                            end
                        end
                    end
                end
            end
        end
        table.sort(cands, function(a, b) return a.d < b.d end)

        local keep = {}
        for i, c in ipairs(cands) do
            if i > G.ObjState.maxLabels then break end
            local e = c.e
            keep[e] = true
            local st = G.ostate[e]
            if not st then
                st = {e = e}
                G.ostate[e] = st
            end
            st.part = e.part

            local fade = math.clamp((c.d - range * 0.55) / (range * 0.45), 0, 0.65)

            if not st.nameLbl then st.nameLbl = G.newOverlayLabel() end
            local nm = T("obj." .. c.ot.key)
            if G.TextCfg.oname.spaced and G.currentLang ~= "ar" then nm = G.spaceText(nm) end
            G.setText(st.nameLbl, nm)
            st.nameLbl.TextColor3 = G.ObjState.color[c.ot.key]
            G.ensureStyle(st.nameLbl, G.TextCfg.oname)
            st.nameLbl.TextTransparency = math.clamp(G.labelMeta[st.nameLbl].baseT + fade, 0, 0.95)

            if G.ObjState.showDist then
                if not st.distLbl then st.distLbl = G.newOverlayLabel() end
                G.setText(st.distLbl, G.fmtDist(G.TextCfg.odist.format, math.floor(c.d)))
                st.distLbl.TextColor3 = C.White
                G.ensureStyle(st.distLbl, G.TextCfg.odist)
                st.distLbl.TextTransparency = math.clamp(G.labelMeta[st.distLbl].baseT + fade, 0, 0.95)
            elseif st.distLbl then
                G.destroyLabel(st.distLbl)
                st.distLbl = nil
            end
        end

        for e in pairs(G.ostate) do
            if not keep[e] then G.clearObjectState(e) end
        end
    end)
end))

---------------------------------------------------------------------
-- رسم النصوص كل فريم (مواضع دقيقة مرقّمة بالبكسل، فما فيه اهتزاز)
---------------------------------------------------------------------
function G.setPos(lbl, p, cfg)
    lbl.Position = UDim2.fromOffset(math.floor(p.X + cfg.ox + 0.5), math.floor(p.Y + cfg.oy + 0.5))
end

track(RunService.RenderStepped:Connect(function()
    if next(G.pstate) == nil and next(G.ostate) == nil then return end
    local cam = workspace.CurrentCamera
    if not cam then return end

    for _, st in pairs(G.pstate) do
        local head, root = st.head, st.root
        local ok = head and head.Parent and root and root.Parent
        for _, pair in ipairs({{st.nameLbl, G.TextCfg.pname}, {st.distLbl, G.TextCfg.pdist}}) do
            local lbl, cfg = pair[1], pair[2]
            if lbl then
                if ok then
                    local world
                    if cfg.pos == "above" then
                        world = head.Position + Vector3.new(0, head.Size.Y / 2 + 0.25, 0)
                    elseif cfg.pos == "below" then
                        world = root.Position - Vector3.new(0, 3, 0)
                    else
                        world = root.Position
                    end
                    local v = cam:WorldToViewportPoint(world)
                    if v.Z > 0 then
                        G.setPos(lbl, v, cfg)
                        lbl.Visible = true
                    else
                        lbl.Visible = false
                    end
                else
                    lbl.Visible = false
                end
            end
        end
    end

    for _, st in pairs(G.ostate) do
        local part = st.part
        local ok = part and part.Parent
        for _, pair in ipairs({{st.nameLbl, G.TextCfg.oname}, {st.distLbl, G.TextCfg.odist}}) do
            local lbl, cfg = pair[1], pair[2]
            if lbl then
                if ok then
                    local pos = part.Position
                    local world
                    if cfg.pos == "above" then
                        world = pos + Vector3.new(0, part.Size.Y / 2, 0)
                    elseif cfg.pos == "below" then
                        world = pos - Vector3.new(0, part.Size.Y / 2, 0)
                    else
                        world = pos
                    end
                    local v = cam:WorldToViewportPoint(world)
                    if v.Z > 0 then
                        G.setPos(lbl, v, cfg)
                        lbl.Visible = true
                    else
                        lbl.Visible = false
                    end
                else
                    lbl.Visible = false
                end
            end
        end
    end
end))

---------------------------------------------------------------------
-- الإضاءة والأجواء (تشتغل فقط وهي مفعّلة، وترجّع إعدادات اللعبة بعد الإغلاق)
---------------------------------------------------------------------
G.lightOrig = nil
G.lightActive = false
G.effectOrig = {}
G.effectsDisabled = false
G.snowPart = nil

function G.captureLighting()
    G.lightOrig = {
        Brightness = Lighting.Brightness,
        ExposureCompensation = Lighting.ExposureCompensation,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        ClockTime = Lighting.ClockTime,
        FogEnd = Lighting.FogEnd,
        FogStart = Lighting.FogStart,
        FogColor = Lighting.FogColor,
        GlobalShadows = Lighting.GlobalShadows
    }
end

function G.disableEffects()
    if G.effectsDisabled then return end
    G.effectsDisabled = true
    G.effectOrig = {}
    for _, e in ipairs(Lighting:GetChildren()) do
        if e:IsA("PostEffect") then
            G.effectOrig[#G.effectOrig + 1] = {e, "Enabled", e.Enabled}
            e.Enabled = false
        elseif e:IsA("Atmosphere") then
            G.effectOrig[#G.effectOrig + 1] = {e, "Density", e.Density}
            G.effectOrig[#G.effectOrig + 1] = {e, "Haze", e.Haze}
            e.Density = 0
            e.Haze = 0
        end
    end
end

function G.restoreEffects()
    if not G.effectsDisabled then return end
    G.effectsDisabled = false
    for _, r in ipairs(G.effectOrig) do
        pcall(function() r[1][r[2]] = r[3] end)
    end
    G.effectOrig = {}
end

function G.restoreLighting()
    if G.lightOrig then
        for k, v in pairs(G.lightOrig) do
            pcall(function() Lighting[k] = v end)
        end
        G.lightOrig = nil
    end
    G.restoreEffects()
    G.lightActive = false
end

function G.setIfDiff(inst, prop, val)
    if inst[prop] ~= val then inst[prop] = val end
end

function G.fogEndFromAmount(a)
    if a <= 0 then return 100000 end
    return math.floor(60 * math.pow(1600, (100 - a) / 100))
end

function G.updateSnow()
    if G.LightCfg.snow then
        local cam = workspace.CurrentCamera
        if not cam then return end
        if not G.snowPart or not G.snowPart.Parent then
            G.snowPart = Instance.new("Part")
            G.snowPart.Name = "CleanESP_Snow"
            G.snowPart.Anchored = true
            G.snowPart.CanCollide = false
            G.snowPart.CanQuery = false
            G.snowPart.CanTouch = false
            G.snowPart.Transparency = 1
            G.snowPart.Size = Vector3.new(70, 1, 70)
            local pe = Instance.new("ParticleEmitter")
            pe.Name = "Flakes"
            pe.Lifetime = NumberRange.new(5, 7)
            pe.Speed = NumberRange.new(14, 20)
            pe.EmissionDirection = Enum.NormalId.Bottom
            pe.SpreadAngle = Vector2.new(20, 20)
            pe.Size = NumberSequence.new(0.25)
            pe.Transparency = NumberSequence.new(0.15)
            pe.Color = ColorSequence.new(Color3.new(1, 1, 1))
            pe.LightEmission = 0.4
            pe.LightInfluence = 0
            pe.RotSpeed = NumberRange.new(-30, 30)
            pe.Parent = G.snowPart
            G.snowPart.Parent = cam
        end
        G.snowPart.CFrame = CFrame.new(cam.CFrame.Position + Vector3.new(0, 30, 0))
        local pe = G.snowPart:FindFirstChild("Flakes")
        if pe then pe.Rate = G.LightCfg.snowAmount * 8 end
    elseif G.snowPart then
        G.snowPart:Destroy()
        G.snowPart = nil
    end
end

track(RunService.RenderStepped:Connect(function()
    pcall(function()
        if G.LightCfg.enabled then
            if not G.lightOrig then G.captureLighting() end
            G.lightActive = true
            local t = G.LightCfg.tint
            local a = G.LightCfg.ambient / 255
            local amb = Color3.new(a * t.R, a * t.G, a * t.B)

            G.setIfDiff(Lighting, "Brightness", G.LightCfg.brightness)
            G.setIfDiff(Lighting, "ExposureCompensation", G.LightCfg.exposure)
            G.setIfDiff(Lighting, "Ambient", amb)
            G.setIfDiff(Lighting, "OutdoorAmbient", amb)
            G.setIfDiff(Lighting, "ClockTime", G.LightCfg.time)
            G.setIfDiff(Lighting, "FogColor", G.LightCfg.fogColor)
            G.setIfDiff(Lighting, "FogStart", 0)
            G.setIfDiff(Lighting, "FogEnd", G.fogEndFromAmount(G.LightCfg.fogAmount))
            G.setIfDiff(Lighting, "GlobalShadows", G.LightCfg.shadows)

            if G.LightCfg.effects then G.restoreEffects() else G.disableEffects() end
        elseif G.lightActive then
            G.restoreLighting()
        end
        G.updateSnow()
    end)
end))

---------------------------------------------------------------------
-- الكاميرا: FOV + منظور أول شخص + حدود التقريب (نرجّع كل شي كما كان عند الإغلاق)
---------------------------------------------------------------------
local camOrig = nil   -- {fov, cameraMode, minZoom, maxZoom}

local function captureCamera()
    local cam = workspace.CurrentCamera
    camOrig = {
        fov = cam and cam.FieldOfView or 70,
        cameraMode = LocalPlayer.CameraMode,
        minZoom = LocalPlayer.CameraMinZoomDistance,
        maxZoom = LocalPlayer.CameraMaxZoomDistance
    }
end

local function restoreCamera()
    if not camOrig then return end
    local cam = workspace.CurrentCamera
    pcall(function()
        if cam then cam.FieldOfView = camOrig.fov end
        LocalPlayer.CameraMode = camOrig.cameraMode
        LocalPlayer.CameraMinZoomDistance = camOrig.minZoom
        LocalPlayer.CameraMaxZoomDistance = camOrig.maxZoom
    end)
    camOrig = nil
end

track(RunService.RenderStepped:Connect(function()
    pcall(function()
        if G.CameraCfg.enabled then
            if not camOrig then captureCamera() end
            local cam = workspace.CurrentCamera
            if cam and cam.FieldOfView ~= G.CameraCfg.fov then cam.FieldOfView = G.CameraCfg.fov end
            local wantMode = G.CameraCfg.firstPerson and Enum.CameraMode.LockFirstPerson or Enum.CameraMode.Classic
            if LocalPlayer.CameraMode ~= wantMode then LocalPlayer.CameraMode = wantMode end
            if G.CameraCfg.zoomEnabled then
                if LocalPlayer.CameraMinZoomDistance ~= G.CameraCfg.zoomMin then
                    LocalPlayer.CameraMinZoomDistance = G.CameraCfg.zoomMin
                end
                if LocalPlayer.CameraMaxZoomDistance ~= G.CameraCfg.zoomMax then
                    LocalPlayer.CameraMaxZoomDistance = G.CameraCfg.zoomMax
                end
            end
        elseif camOrig then
            restoreCamera()
        end
    end)
end))

---------------------------------------------------------------------
-- عداد FPS / Ping (فوق الشاشة، يتبع إعداداته الخاصة)
---------------------------------------------------------------------
local fpsLabel = make("TextLabel", {
    BackgroundColor3 = Color3.fromRGB(14, 14, 18),
    BackgroundTransparency = 0.25,
    AnchorPoint = Vector2.new(0, 0),
    Position = UDim2.fromOffset(14, 14),
    Size = UDim2.fromOffset(0, 0),
    AutomaticSize = Enum.AutomaticSize.XY,
    Font = Enum.Font.GothamBold,
    Text = "",
    TextColor3 = Color3.fromRGB(120, 230, 150),
    TextSize = 14,
    Visible = false
}, G.Overlay)
corner(fpsLabel, 6)
make("UIPadding", {
    PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5),
    PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)
}, fpsLabel)

local fpsFrames, fpsAcc, fpsShown = 0, 0, 0
local statsOk, Stats = pcall(function() return game:GetService("Stats") end)
local netOk, Network = pcall(function() return Stats.Network end)

track(RunService.RenderStepped:Connect(function(dt)
    if not G.CameraCfg.showFps then
        if fpsLabel.Visible then fpsLabel.Visible = false end
        return
    end
    fpsLabel.Visible = true
    fpsLabel.TextSize = G.CameraCfg.fpsSize
    fpsFrames += 1
    fpsAcc += dt
    if fpsAcc >= 0.5 then
        fpsShown = math.floor(fpsFrames / fpsAcc + 0.5)
        fpsFrames, fpsAcc = 0, 0
        local ping = 0
        if statsOk and netOk then
            local ok, v = pcall(function() return Network.ServerStatsItem["Data Ping"]:GetValue() end)
            if ok and v then ping = math.floor(v) end
        end
        fpsLabel.Text = string.format("FPS %d  ·  %d ms", fpsShown, ping)
    end
end))

---------------------------------------------------------------------
-- إظهار / إخفاء القائمة + حفظ واسترجاع حالة الماوس (يحل مشكلة الكاميرا)
---------------------------------------------------------------------
-- نتتبع حالة الماوس اللي تحطها اللعبة، عشان نرجّعها بالضبط بعد إغلاق القائمة أو إصلاح الكاميرا
G.gameMouse = {UserInputService.MouseBehavior, UserInputService.MouseIconEnabled}
G.restoreMouse = nil      -- {behavior, icon} نثبّتها لفترة قصيرة بعد إغلاق القائمة
G.restoreUntil = 0
G.cameraFixed = false     -- true = زر إصلاح الكاميرا شغّال الحين (يبقى لين تطفيه أو تفتح القائمة)
G.lastLocked = G.lastLocked or {Enum.MouseBehavior.LockCenter, false}

track(RunService.Heartbeat:Connect(function()
    if G.menuVisible or GuiService.MenuIsOpen or G.cameraFixed then return end
    if os.clock() < G.restoreUntil then return end
    G.gameMouse[1] = UserInputService.MouseBehavior
    G.gameMouse[2] = UserInputService.MouseIconEnabled
    if G.gameMouse[1] ~= Enum.MouseBehavior.Default then
        G.lastLocked = {G.gameMouse[1], G.gameMouse[2]}
    end
end))

-- وقت القائمة (أو قائمة ESC) نفك قفل الماوس كل فريم.
-- وقت "إصلاح الكاميرا" نفرض القفل والإخفاء كل فريم بثبات، بدل ما نسويها مرة وحدة وتنفلت.
-- وبعد إغلاق القائمة نرجّع حالة اللعبة ونثبّتها لفترة قصيرة عشان ما ترجع العالقة القديمة.
RunService:BindToRenderStep("CleanESP_Cursor", Enum.RenderPriority.Last.Value + 10, function()
    if G.menuVisible or GuiService.MenuIsOpen then
        if G.cameraFixed then G.cameraFixed = false end
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    elseif G.cameraFixed then
        local lk = G.lastLocked
        UserInputService.MouseBehavior = lk[1]
        UserInputService.MouseIconEnabled = lk[2]
        pcall(function() Mouse.Icon = "" end)
    elseif G.restoreMouse and os.clock() < G.restoreUntil then
        if UserInputService.MouseBehavior ~= G.restoreMouse[1] then
            UserInputService.MouseBehavior = G.restoreMouse[1]
        end
        if UserInputService.MouseIconEnabled ~= G.restoreMouse[2] then
            UserInputService.MouseIconEnabled = G.restoreMouse[2]
        end
    end
end)

G.savedMouse = nil
G.noticeFrame = nil

function G.dismissNotice()
    if G.noticeFrame then
        local f = G.noticeFrame
        G.noticeFrame = nil
        tween(f, 0.3, {Position = UDim2.new(0.5, 0, 0, -120)}, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        task.delay(0.35, function() f:Destroy() end)
    end
end

-- إصلاح الكاميرا: يرجّع قفل الماوس لآخر حالة قفل شفتها من اللعبة
function G.fixCamera()
    if G.menuVisible then G.setMenu(false) end
    G.cameraFixed = not G.cameraFixed
    if G.cameraFixed then
        G.showNotice(T("notify.camFixed"), T("notify.camFixedSub"), G.keyName(G.fixKey), 3)
    else
        G.showNotice(T("notify.camReleased"), "", G.keyName(G.fixKey), 2)
    end
end

function G.setMenu(v)
    if v == G.menuVisible then return end
    G.menuVisible = v
    local target = G.AppCfg.scale / 100
    if v then
        G.dismissNotice()
        G.savedMouse = {G.gameMouse[1], G.gameMouse[2]}
        G.restoreMouse = nil
        MainFrame.Visible = true
        G.MainScale.Scale = target * 0.92
        tween(MainFrame, 0.25, {GroupTransparency = 0})
        tween(G.MainScale, 0.3, {Scale = target}, Enum.EasingStyle.Back)
    else
        G.flushSave()
        tween(MainFrame, 0.18, {GroupTransparency = 1})
        tween(G.MainScale, 0.18, {Scale = target * 0.94})
        task.delay(0.18, function()
            if not G.menuVisible then MainFrame.Visible = false end
        end)
        -- نرجّع حالة الماوس زي ما كانت قبل فتح القائمة (فتتحرك الكاميرا بدون كليك يمين)
        local wasLocked = G.savedMouse and G.savedMouse[1] ~= Enum.MouseBehavior.Default
        if wasLocked then
            -- لو بعد ثانية ونص الكاميرا لسا عالقة، ننبّه المستخدم بزر الإصلاح
            task.delay(1.7, function()
                if not G.menuVisible and not GuiService.MenuIsOpen and not G.cameraFixed
                    and UserInputService.MouseBehavior == Enum.MouseBehavior.Default then
                    G.showNotice(T("hint.camTitle"), T("hint.camSub"), G.keyName(G.fixKey), 9)
                end
            end)
        end
        if G.savedMouse then
            G.restoreMouse = {G.savedMouse[1], G.savedMouse[2]}
            G.restoreUntil = os.clock() + 1.5
            pcall(function()
                UserInputService.MouseBehavior = G.savedMouse[1]
                UserInputService.MouseIconEnabled = G.savedMouse[2]
            end)
            G.savedMouse = nil
        end
    end
end

track(UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if G.keyListening then
        G.applyMenuKey(input.KeyCode)
        return
    end
    if UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode == G.fixKey and G.fixKey ~= menuKey then
        G.fixCamera()
    elseif input.KeyCode == menuKey then
        G.setMenu(not G.menuVisible)
    end
end))

---------------------------------------------------------------------
-- إشعار التشغيل (يظهر وينسحب بنفسه)
---------------------------------------------------------------------
function G.showNotice(titleText, subText, keyText, duration)
    G.dismissNotice()
    local f = make("Frame", {
        BackgroundColor3 = Color3.fromRGB(22, 22, 28),
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, -120),
        Size = UDim2.fromOffset(400, 0),
        AutomaticSize = Enum.AutomaticSize.Y
    }, ScreenGui)
    corner(f, 10)
    make("UIStroke", {Color = C.Accent, Thickness = 1, Transparency = 0.35, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, f)
    make("UIPadding", {
        PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14)
    }, f)

    local dot = make("Frame", {
        BackgroundColor3 = C.Accent,
        Position = UDim2.fromOffset(0, 6),
        Size = UDim2.fromOffset(10, 10)
    }, f)
    corner(dot, 5)

    make("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(22, 0),
        Size = UDim2.new(1, -112, 0, 22),
        Font = Enum.Font.GothamBold,
        Text = titleText or "Violence District  ·  v5.3",
        TextColor3 = C.White,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left
    }, f)

    local sub = make("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(22, 24),
        Size = UDim2.new(1, -112, 0, 18),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Enum.Font.GothamBold,
        Text = subText or (T("notify.sub") .. (G.hasFS and "" or ("\n" .. T("set.noFiles")))),
        TextColor3 = C.Dim,
        TextSize = 12,
        TextWrapped = true,
        TextTruncate = Enum.TextTruncate.None,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top
    }, f)

    local cap = make("TextLabel", {
        BackgroundColor3 = C.Row,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(78, 30),
        Font = Enum.Font.GothamBold,
        Text = keyText or G.keyName(menuKey),
        TextColor3 = C.White,
        TextSize = 13,
        TextWrapped = false
    }, f)
    corner(cap, 6)
    make("UIStroke", {Color = C.BoxBorder, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, cap)

    G.noticeFrame = f
    tween(f, 0.55, {Position = UDim2.new(0.5, 0, 0, 24)}, Enum.EasingStyle.Back)
    task.delay(duration or 6, function()
        if G.noticeFrame == f then G.dismissNotice() end
    end)
end

---------------------------------------------------------------------
-- تنظيف عند إعادة التشغيل
---------------------------------------------------------------------
_G.CleanESP_Cleanup = function()
    pcall(G.flushSave)
    pcall(restoreCamera)
    pcall(function() RunService:UnbindFromRenderStep("CleanESP_Cursor") end)
    if G.menuVisible and G.savedMouse then
        pcall(function()
            UserInputService.MouseBehavior = G.savedMouse[1]
            UserInputService.MouseIconEnabled = G.savedMouse[2]
        end)
    end
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    pcall(function() G.expandVal:Destroy() end)
    pcall(G.restoreLighting)
    if G.snowPart then pcall(function() G.snowPart:Destroy() end) end
    if ScreenGui then ScreenGui:Destroy() end
    if G.Overlay then G.Overlay:Destroy() end
    for plr in pairs(G.skeletons) do G.removeSkeleton(plr) end
    for _, plr in ipairs(Players:GetPlayers()) do
        local char = plr.Character
        if char then
            local hl = char:FindFirstChild("Fast_ESP_HL")
            if hl then hl:Destroy() end
        end
    end
end

---------------------------------------------------------------------
-- بداية التشغيل: القائمة مخفية، نرجّع آخر إعدادات هذا الحساب ونعرض الإشعار
---------------------------------------------------------------------
G.applyFontId(G.defaultFontFor(G.currentLang))

if type(G.StoreData.autosave) == "table" then
    G.applySnapshot(G.StoreData.autosave)
end
G.refreshProfileList()
G.applyAppearance()
G.bumpStyle()
G.showNotice()
