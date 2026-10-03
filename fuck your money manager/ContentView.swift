import SwiftUI
import UIKit
import Combine

// MARK: - Warna
// Dasar netral memakai warna sistem iOS (otomatis terang/gelap),
// dengan satu warna aksen: biru kobalt.

enum Palette {
    static let background  = Color(uiColor: .systemGroupedBackground)
    static let surface     = Color(uiColor: .secondarySystemGroupedBackground)
    static let fill        = Color(uiColor: .tertiarySystemFill)
    static let ink         = Color(uiColor: .label)
    static let muted       = Color(uiColor: .secondaryLabel)
    static let faint       = Color(uiColor: .tertiaryLabel)
    static let placeholder = Color(uiColor: .placeholderText)
    static let line        = Color(uiColor: .separator)

    static let accent   = dynamic(light: (44, 84, 201, 1),    dark: (134, 162, 255, 1))
    static let onAccent = dynamic(light: (250, 250, 252, 1),  dark: (12, 18, 34, 1))
    static let shadow   = dynamic(light: (28, 32, 52, 0.10),  dark: (0, 0, 0, 0))

    nonisolated private static func dynamic(
        light: (CGFloat, CGFloat, CGFloat, CGFloat),
        dark: (CGFloat, CGFloat, CGFloat, CGFloat)
    ) -> Color {
        Color(uiColor: UIColor { traits in
            let c = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: c.0 / 255, green: c.1 / 255, blue: c.2 / 255, alpha: c.3)
        })
    }
}

// Aturan sudut: kartu & pesan 20pt, tombol 12pt, pemilih periode berbentuk kapsul.

// MARK: - Info aplikasi

enum AppInfo {
    // GANTI dengan link halaman kebijakan privasi kamu (misalnya dari Netlify)
    static let privacyPolicyURL = URL(string: "https://ganti-dengan-link-kamu.netlify.app")!
}

// MARK: - Format Rupiah

enum Rupiah {
    static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "id_ID")
        f.groupingSeparator = "."
        f.usesGroupingSeparator = true
        f.maximumFractionDigits = 0
        return f
    }()

    static func number(_ value: Int) -> String {
        formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    static func text(_ value: Int) -> String {
        "Rp " + number(value)
    }
}

// MARK: - Kategori

enum SpendCategory: String, Codable, CaseIterable, Identifiable {
    case makan
    case transport
    case fun
    case kebutuhan

    var id: String { rawValue }

    var title: String {
        switch self {
        case .makan:     return "Makan"
        case .transport: return "Gojek/Grab"
        case .fun:       return "Have Fun"
        case .kebutuhan: return "Spending Kebutuhan"
        }
    }

    var icon: String {
        switch self {
        case .makan:     return "fork.knife"
        case .transport: return "scooter"
        case .fun:       return "party.popper.fill"
        case .kebutuhan: return "cart.fill"
        }
    }

    var color: Color {
        switch self {
        case .makan:     return Color(red: 228/255, green: 87/255,  blue: 46/255)
        case .transport: return Color(red: 31/255,  green: 157/255, blue: 107/255)
        case .fun:       return Color(red: 192/255, green: 79/255,  blue: 209/255)
        case .kebutuhan: return Color(red: 58/255,  green: 123/255, blue: 213/255)
        }
    }

    /// Urutan kategori berdasarkan nominal:
    /// - sampai Rp 30.000   → Makan, Gojek/Grab, Have Fun, Spending Kebutuhan
    /// - Rp 30.001-50.000   → Gojek/Grab, Have Fun, Spending Kebutuhan, Makan
    /// - di atas Rp 50.000  → Have Fun, Spending Kebutuhan, Gojek/Grab, Makan
    static func suggested(for amount: Int) -> [SpendCategory] {
        switch amount {
        case ...30_000: return [.makan, .transport, .fun, .kebutuhan]
        case ...50_000: return [.transport, .fun, .kebutuhan, .makan]
        default:        return [.fun, .kebutuhan, .transport, .makan]
        }
    }
}

// MARK: - Kategori buatan sendiri

struct CustomCategory: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var icon: String
    var colorIndex: Int
    var lastUsed: Date

    static let icons = [
        "tag.fill", "cup.and.saucer.fill", "fuelpump.fill", "iphone",
        "gift.fill", "tshirt.fill", "house.fill", "cross.case.fill",
        "book.fill", "gamecontroller.fill", "pawprint.fill", "creditcard.fill"
    ]

    static let colors: [Color] = [
        Color(red: 214/255, green: 137/255, blue: 16/255),
        Color(red: 0/255,   green: 150/255, blue: 170/255),
        Color(red: 199/255, green: 62/255,  blue: 110/255),
        Color(red: 94/255,  green: 110/255, blue: 220/255),
        Color(red: 120/255, green: 140/255, blue: 40/255),
        Color(red: 150/255, green: 90/255,  blue: 60/255)
    ]

    var color: Color {
        Self.colors[abs(colorIndex) % Self.colors.count]
    }
}

/// Satu pilihan kategori di layar: bawaan atau buatan sendiri.
enum CategoryChoice: Hashable, Identifiable {
    case builtIn(SpendCategory)
    case custom(CustomCategory)

    var id: String {
        switch self {
        case .builtIn(let c): return "bawaan-" + c.rawValue
        case .custom(let c):  return "custom-" + c.id.uuidString
        }
    }

    var title: String {
        switch self {
        case .builtIn(let c): return c.title
        case .custom(let c):  return c.name
        }
    }

    var icon: String {
        switch self {
        case .builtIn(let c): return c.icon
        case .custom(let c):  return c.icon
        }
    }

    var color: Color {
        switch self {
        case .builtIn(let c): return c.color
        case .custom(let c):  return c.color
        }
    }
}

// MARK: - Periode

enum Period: String, CaseIterable, Identifiable {
    case week, month, year, all, custom

    var id: String { rawValue }

    var shortTitle: String {
        switch self {
        case .week:   return "Minggu"
        case .month:  return "Bulan"
        case .year:   return "Tahun"
        case .all:    return "Semua"
        case .custom: return "Pilih tanggal"
        }
    }

    var isSteppable: Bool {
        self == .week || self == .month || self == .year
    }
}

/// Rentang tanggal; `end` tidak termasuk (eksklusif).
struct DateRange: Equatable {
    let start: Date
    let end: Date

    func contains(_ date: Date) -> Bool {
        date >= start && date < end
    }
}

// MARK: - Data

struct Spend: Identifiable, Codable, Equatable {
    var id = UUID()
    var amount: Int
    var date: Date
    // false kalau dicatat untuk tanggal lain (jamnya bukan jam asli).
    // nil = data lama, dianggap jamnya asli.
    var timeKnown: Bool?
    // nil = catatan lama sebelum ada kategori
    var category: SpendCategory?
    // Diisi kalau memakai kategori buatan sendiri.
    // Namanya ikut disimpan supaya tetap terbaca walau kategorinya dihapus.
    var customCategoryID: UUID?
    var customCategoryName: String?
}

struct DayGroup: Identifiable {
    let day: Date
    let items: [Spend]
    var id: Date { day }
    var total: Int { items.reduce(0) { $0 + $1.amount } }
}

final class SpendStore: ObservableObject {
    @Published private(set) var items: [Spend] = []
    @Published private(set) var customCategories: [CustomCategory] = []
    private let key = "pengeluaran-v1"
    private let customKey = "kategori-custom-v1"

    init() { load() }

    var total: Int { items.reduce(0) { $0 + $1.amount } }

    var todayItems: [Spend] {
        items.filter { Calendar.current.isDateInToday($0.date) }
    }

    var todayTotal: Int { todayItems.reduce(0) { $0 + $1.amount } }

    func spends(in range: DateRange?) -> [Spend] {
        guard let range else { return items }
        return items.filter { range.contains($0.date) }
    }

    static func groupByDay(_ spends: [Spend]) -> [DayGroup] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: spends) { cal.startOfDay(for: $0.date) }
        return groups
            .map { DayGroup(day: $0.key, items: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.day > $1.day }
    }

    @discardableResult
    func add(_ amount: Int, choice: CategoryChoice, on date: Date, timeKnown: Bool) -> Spend {
        var spend = Spend(amount: amount, date: date, timeKnown: timeKnown)
        apply(choice, to: &spend)
        items.append(spend)
        save()
        markUsed(choice)
        return spend
    }

    func setCategory(_ choice: CategoryChoice, for spend: Spend) {
        guard let index = items.firstIndex(where: { $0.id == spend.id }) else { return }
        apply(choice, to: &items[index])
        save()
        markUsed(choice)
    }

    private func apply(_ choice: CategoryChoice, to spend: inout Spend) {
        switch choice {
        case .builtIn(let category):
            spend.category = category
            spend.customCategoryID = nil
            spend.customCategoryName = nil
        case .custom(let custom):
            spend.category = nil
            spend.customCategoryID = custom.id
            spend.customCategoryName = custom.name
        }
    }

    // MARK: Kategori

    /// Urutan pilihan saat nominal diketik:
    /// 1. kategori bawaan teratas sesuai nominal
    /// 2-3. kategori buatan sendiri (yang paling baru dipakai/dibuat)
    /// lalu sisa kategori bawaan, lalu sisa kategori buatan sendiri.
    func orderedChoices(for amount: Int) -> [CategoryChoice] {
        let builtIns = SpendCategory.suggested(for: amount).map { CategoryChoice.builtIn($0) }
        let customs = customCategories
            .sorted { $0.lastUsed > $1.lastUsed }
            .map { CategoryChoice.custom($0) }
        guard let first = builtIns.first else { return customs }
        return [first]
            + Array(customs.prefix(2))
            + Array(builtIns.dropFirst())
            + Array(customs.dropFirst(2))
    }

    var allChoices: [CategoryChoice] {
        SpendCategory.allCases.map { CategoryChoice.builtIn($0) }
            + customCategories.map { CategoryChoice.custom($0) }
    }

    func choice(for spend: Spend) -> CategoryChoice? {
        if let id = spend.customCategoryID {
            guard let custom = customCategories.first(where: { $0.id == id }) else { return nil }
            return .custom(custom)
        }
        return spend.category.map { CategoryChoice.builtIn($0) }
    }

    func addCustomCategory(name: String, icon: String) {
        let nextColor = (customCategories.map(\.colorIndex).max() ?? -1) + 1
        let category = CustomCategory(name: name, icon: icon, colorIndex: nextColor, lastUsed: .now)
        customCategories.append(category)
        saveCustom()
    }

    func deleteCustomCategories(at offsets: IndexSet) {
        customCategories.remove(atOffsets: offsets)
        saveCustom()
    }

    func isNameTaken(_ name: String) -> Bool {
        let n = name.lowercased()
        return customCategories.contains { $0.name.lowercased() == n }
            || SpendCategory.allCases.contains { $0.title.lowercased() == n }
    }

    private func markUsed(_ choice: CategoryChoice) {
        guard case .custom(let custom) = choice,
              let index = customCategories.firstIndex(where: { $0.id == custom.id })
        else { return }
        customCategories[index].lastUsed = .now
        saveCustom()
    }

    func remove(_ spend: Spend) {
        items.removeAll { $0.id == spend.id }
        save()
    }

    func restore(_ spends: [Spend]) {
        items.append(contentsOf: spends)
        save()
    }

    @discardableResult
    func removeAll() -> [Spend] {
        let old = items
        items = []
        save()
        return old
    }

    // Disimpan di memori iPhone, tetap ada walau aplikasi ditutup
    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([Spend].self, from: data) {
            items = decoded
        }
        if let data = UserDefaults.standard.data(forKey: customKey),
           let decoded = try? JSONDecoder().decode([CustomCategory].self, from: data) {
            customCategories = decoded
        }
    }

    private func saveCustom() {
        if let data = try? JSONEncoder().encode(customCategories) {
            UserDefaults.standard.set(data, forKey: customKey)
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

// MARK: - Tampilan

struct ContentView: View {
    @StateObject private var store = SpendStore()
    @State private var input = ""
    @State private var confirmClear = false
    @State private var toast: Toast?
    @State private var pickedDate: Date? = nil   // nil = hari ini
    @State private var offset = 0                 // 0 = periode sekarang, -1 = sebelumnya, dst.
    @State private var showRangeSheet = false
    @State private var showCategorySheet = false
    @AppStorage("periode") private var periodRaw = Period.week.rawValue
    @AppStorage("rentangMulai") private var customStartRaw: Double = 0
    @AppStorage("rentangSampai") private var customEndRaw: Double = 0
    @FocusState private var inputFocused: Bool
    @Namespace private var periodSelection
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false      // animasi pembuka sudah jalan?
    @State private var revealTotal = false   // angka total sudah "bergulir" ke nilai aslinya?

    struct Toast: Identifiable {
        let id = UUID()
        let message: String
        let undo: () -> Void
    }

    /// Semua animasi lewat sini, jadi otomatis mati saat "Kurangi Gerakan" aktif.
    private var motion: Animation? {
        reduceMotion ? nil : .snappy(duration: 0.3)
    }

    private var inputAmount: Int {
        Int(input.filter { $0.isASCII && $0.isNumber }) ?? 0
    }

    // Kalau yang dipilih hari ini, simpan sebagai nil supaya
    // besok otomatis ikut ke tanggal baru.
    private var dateBinding: Binding<Date> {
        Binding(
            get: { pickedDate ?? .now },
            set: { newValue in
                pickedDate = Calendar.current.isDateInToday(newValue) ? nil : newValue
            }
        )
    }

    // MARK: Periode yang dipilih

    private var period: Period {
        Period(rawValue: periodRaw) ?? .week
    }

    private var customStart: Date {
        customStartRaw > 0
            ? Date(timeIntervalSince1970: customStartRaw)
            : (Calendar.current.dateInterval(of: .month, for: .now)?.start ?? .now)
    }

    private var customEnd: Date {
        customEndRaw > 0
            ? Date(timeIntervalSince1970: customEndRaw)
            : Calendar.current.startOfDay(for: .now)
    }

    /// nil = semua waktu
    private var range: DateRange? {
        var cal = Calendar.current
        cal.firstWeekday = 2 // minggu dimulai hari Senin

        func shifted(_ unit: Calendar.Component) -> DateRange? {
            guard let base = cal.dateInterval(of: unit, for: .now),
                  let start = cal.date(byAdding: unit, value: offset, to: base.start),
                  let end = cal.date(byAdding: unit, value: 1, to: start)
            else { return nil }
            return DateRange(start: start, end: end)
        }

        switch period {
        case .week:  return shifted(.weekOfYear)
        case .month: return shifted(.month)
        case .year:  return shifted(.year)
        case .all:   return nil
        case .custom:
            let start = cal.startOfDay(for: customStart)
            let endDay = cal.startOfDay(for: customEnd)
            let end = cal.date(byAdding: .day, value: 1, to: endDay) ?? endDay
            return DateRange(start: start, end: end)
        }
    }

    private var visibleItems: [Spend] { store.spends(in: range) }

    private var visibleTotal: Int { visibleItems.reduce(0) { $0 + $1.amount } }

    private var periodTitle: (main: String, sub: String?) {
        guard let r = range else { return ("Semua waktu", nil) }
        let lastDay = Calendar.current.date(byAdding: .day, value: -1, to: r.end) ?? r.end

        switch period {
        case .week:
            let main: String
            switch offset {
            case 0:  main = "Minggu ini"
            case -1: main = "Minggu lalu"
            default: main = "\(-offset) minggu lalu"
            }
            return (main, formatSpan(r.start, lastDay))
        case .month:
            let name = format(r.start, "MMMM yyyy")
            switch offset {
            case 0:  return ("Bulan ini", name)
            case -1: return ("Bulan lalu", name)
            default: return (name, nil)
            }
        case .year:
            let year = format(r.start, "yyyy")
            switch offset {
            case 0:  return ("Tahun ini", year)
            case -1: return ("Tahun lalu", year)
            default: return ("Tahun \(year)", nil)
            }
        case .custom:
            return (formatSpan(r.start, lastDay), "Ketuk untuk mengubah tanggal")
        case .all:
            return ("Semua waktu", nil)
        }
    }

    private func selectPeriod(_ newPeriod: Period) {
        withAnimation(motion) {
            periodRaw = newPeriod.rawValue
            offset = 0
        }
    }

    private func applyCustomRange(_ from: Date, _ to: Date) {
        let cal = Calendar.current
        var start = cal.startOfDay(for: from)
        var end = cal.startOfDay(for: to)
        if start > end { swap(&start, &end) }
        withAnimation(motion) {
            customStartRaw = start.timeIntervalSince1970
            customEndRaw = end.timeIntervalSince1970
            periodRaw = Period.custom.rawValue
            offset = 0
        }
    }

    // MARK: Layout utama

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .entrance(appeared, delay: 0, animated: !reduceMotion)
            composer
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .entrance(appeared, delay: 0.05, animated: !reduceMotion)
            historyList
                .padding(.top, 4)
                .entrance(appeared, delay: 0.1, animated: !reduceMotion)
        }
        .background(Palette.background.ignoresSafeArea())
        .onAppear(perform: playEntrance)
        .overlay(alignment: .bottom) { toastView }
        .confirmationDialog("Hapus semua catatan?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Hapus semua", role: .destructive, action: clearAll)
            Button("Batal", role: .cancel) {}
        } message: {
            Text("Semua catatan dari semua tanggal akan dihapus. Kamu masih bisa membatalkannya beberapa detik setelahnya.")
        }
        .sheet(isPresented: $showCategorySheet) {
            CategorySheet(store: store)
        }
        .sheet(isPresented: $showRangeSheet) {
            RangeSheet(start: customStart, end: customEnd) { from, to in
                applyCustomRange(from, to)
            }
        }
        .tint(Palette.accent)
    }

    // MARK: Header

    private var header: some View {
        // Saat mengetik, header diringkas supaya pilihan kategori muat di atas keyboard
        let compact = inputFocused
        let title = periodTitle
        // Sebelum animasi pembuka, angka mulai dari 0 lalu bergulir ke nilai asli
        let shownTotal = revealTotal ? visibleTotal : 0
        let shownToday = revealTotal ? store.todayTotal : 0

        return VStack(alignment: .leading, spacing: 0) {
            if !compact {
                periodPicker
                    .padding(.bottom, 22)
                    .transition(.opacity)
            }

            rangeRow(title, compact: compact)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("Rp")
                    .font(.system(size: compact ? 17 : 22, weight: .regular))
                    .foregroundStyle(Palette.muted)
                Text(Rupiah.number(shownTotal))
                    .font(.system(size: compact ? 36 : 52, weight: .light))
                    .tracking(-0.5)
                    .monospacedDigit()
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .contentTransition(.numericText(value: Double(shownTotal)))
            }
            .padding(.top, compact ? 2 : 8)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Total \(Rupiah.text(visibleTotal))")

            if !compact {
                HStack(spacing: 6) {
                    Text("Hari ini")
                        .foregroundStyle(Palette.muted)
                    Text(Rupiah.text(shownToday))
                        .monospacedDigit()
                        .foregroundStyle(Palette.ink)
                        .contentTransition(.numericText())
                }
                .font(.subheadline)
                .padding(.top, 6)
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture { inputFocused = false }
        .animation(motion, value: compact)
    }

    private var periodPicker: some View {
        HStack(spacing: 2) {
            ForEach([Period.week, .month, .year, .all]) { item in
                periodSegment(item.shortTitle, selected: period == item) {
                    selectPeriod(item)
                }
            }
            periodSegment(Period.custom.shortTitle, icon: "calendar", selected: period == .custom) {
                showRangeSheet = true
            }
        }
        .padding(3)
        .background(Palette.fill, in: Capsule())
    }

    private func periodSegment(
        _ title: String,
        icon: String? = nil,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Group {
                if let icon {
                    Image(systemName: icon)
                        .frame(width: 22)
                } else {
                    Text(title)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                }
            }
            .font(.subheadline.weight(selected ? .semibold : .regular))
            .foregroundStyle(selected ? Palette.ink : Palette.muted)
            .padding(.horizontal, 10)
            .frame(height: 30)
            .background {
                if selected {
                    Capsule()
                        .fill(Palette.surface)
                        .shadow(color: Palette.shadow, radius: 3, y: 1)
                        .matchedGeometryEffect(id: "periode", in: periodSelection)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func rangeRow(_ title: (main: String, sub: String?), compact: Bool) -> some View {
        HStack(alignment: .center, spacing: 8) {
            HStack(spacing: 6) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title.main)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.ink)
                    if let sub = title.sub, !compact {
                        Text(sub)
                            .font(.footnote)
                            .foregroundStyle(Palette.muted)
                    }
                }
                if period == .custom && !compact {
                    Image(systemName: "pencil")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Palette.accent)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if period == .custom && !compact {
                    showRangeSheet = true
                } else {
                    inputFocused = false
                }
            }

            Spacer(minLength: 8)

            if period.isSteppable && !compact {
                HStack(spacing: 6) {
                    stepButton("chevron.left", label: "Periode sebelumnya", enabled: true) {
                        offset -= 1
                    }
                    stepButton("chevron.right", label: "Periode berikutnya", enabled: offset < 0) {
                        offset += 1
                    }
                }
            }
        }
    }

    private func stepButton(
        _ icon: String,
        label: String,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            withAnimation(motion) { action() }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(enabled ? Palette.ink : Palette.faint)
                .frame(width: 34, height: 34)
                .background(Palette.fill, in: Circle())
        }
        .buttonStyle(PressableStyle())
        .disabled(!enabled)
        .accessibilityLabel(label)
    }

    // MARK: Kartu input

    private var composer: some View {
        VStack(spacing: 0) {
            amountRow
                .padding(.leading, 16)
                .padding(.trailing, 10)
                .frame(height: 64)
            hairline
            dateRow
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            if inputAmount > 0 {
                hairline
                categoryPicker
                    .padding(12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .animation(motion, value: inputAmount > 0)
    }

    private var hairline: some View {
        Rectangle()
            .fill(Palette.line)
            .frame(height: 0.5)
            .padding(.leading, 16)
    }

    private var amountRow: some View {
        HStack(spacing: 8) {
            Text("Rp")
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(Palette.muted)

            TextField("", text: $input, prompt: Text("0").foregroundStyle(Palette.placeholder))
                .keyboardType(.numberPad)
                .font(.system(size: 30, weight: .medium).monospacedDigit())
                .foregroundStyle(Palette.ink)
                .focused($inputFocused)
                .accessibilityLabel("Nominal pengeluaran")
                .onChange(of: input) { _, newValue in
                    let digits = String(
                        newValue
                            .filter { $0.isASCII && $0.isNumber }
                            .drop(while: { $0 == "0" })
                            .prefix(13)
                    )
                    let formatted = digits.isEmpty ? "" : Rupiah.number(Int(digits) ?? 0)
                    if formatted != newValue { input = formatted }
                }

            if !input.isEmpty {
                Button {
                    input = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Palette.faint)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Hapus nominal")
            }
        }
    }

    private var dateRow: some View {
        HStack(spacing: 8) {
            Label("Tanggal", systemImage: "calendar")
                .font(.subheadline)
                .foregroundStyle(pickedDate == nil ? Palette.muted : Palette.accent)

            Spacer(minLength: 4)

            if pickedDate != nil {
                Button("Hari ini") {
                    withAnimation(motion) { pickedDate = nil }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.accent)
                .buttonStyle(.plain)
                .padding(.horizontal, 4)
            }

            DatePicker("Tanggal", selection: dateBinding, in: ...Date.now, displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.compact)
                .environment(\.locale, Locale(identifier: "id_ID"))
        }
        .padding(.leading, 8)
        .padding(.vertical, 2)
        .background(
            pickedDate == nil ? Color.clear : Palette.accent.opacity(0.10),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
    }

    // MARK: Pilihan kategori (muncul saat nominal diketik)

    private var categoryPicker: some View {
        let ordered = store.orderedChoices(for: inputAmount)
        let top = Array(ordered.prefix(3))
        let rest = Array(ordered.dropFirst(3))

        return HStack(alignment: .top, spacing: 12) {
            Text("Ketuk kategori untuk menyimpan")
                .font(.footnote)
                .foregroundStyle(Palette.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 4)
                .padding(.top, 12)

            VStack(spacing: 6) {
                ForEach(Array(top.enumerated()), id: \.element.id) { index, choice in
                    categoryButton(choice, isTop: index == 0)
                }
                HStack(spacing: 6) {
                    if let next = rest.first {
                        categoryButton(next, isTop: false)
                    }
                    moreMenu(Array(rest.dropFirst()))
                }
            }
            .frame(width: 228)
        }
        .animation(motion, value: ordered.map(\.id))
    }

    private func categoryButton(_ choice: CategoryChoice, isTop: Bool) -> some View {
        Button {
            add(choice)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: choice.icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isTop ? Palette.onAccent : Palette.ink)
                    .frame(width: 26, height: 26)
                    .background(
                        isTop ? Palette.onAccent.opacity(0.18) : Palette.surface,
                        in: Circle()
                    )
                Text(choice.title)
                    .font(.subheadline.weight(isTop ? .semibold : .regular))
                    .foregroundStyle(isTop ? Palette.onAccent : Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .frame(height: 42)
            .background(
                isTop ? Palette.accent : Palette.fill,
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
    }

    /// Tombol "…": kategori lain + tambah/kelola kategori
    private func moreMenu(_ others: [CategoryChoice]) -> some View {
        Menu {
            ForEach(others) { choice in
                Button {
                    add(choice)
                } label: {
                    Label(choice.title, systemImage: choice.icon)
                }
            }
            if !others.isEmpty {
                Divider()
            }
            Button {
                showCategorySheet = true
            } label: {
                Label("Tambah atau kelola kategori", systemImage: "plus")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Palette.ink)
                .frame(width: 42, height: 42)
                .background(Palette.fill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .accessibilityLabel("Kategori lainnya")
    }

    // MARK: Riwayat

    @ViewBuilder
    private var historyList: some View {
        let groups = SpendStore.groupByDay(visibleItems)
        if groups.isEmpty {
            emptyState
        } else {
            List {
                ForEach(groups) { group in
                    Section {
                        ForEach(group.items) { spend in
                            row(spend)
                                .listRowBackground(Palette.surface)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        delete(spend)
                                    } label: {
                                        Label("Hapus", systemImage: "trash")
                                    }
                                }
                                .contextMenu {
                                    ForEach(store.allChoices) { choice in
                                        Button {
                                            withAnimation(motion) { store.setCategory(choice, for: spend) }
                                        } label: {
                                            Label(choice.title, systemImage: choice.icon)
                                        }
                                    }
                                }
                        }
                    } header: {
                        HStack(alignment: .firstTextBaseline) {
                            Text(dayTitle(group.day))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Palette.ink)
                            Spacer()
                            Text(Rupiah.text(group.total))
                                .font(.subheadline)
                                .monospacedDigit()
                                .foregroundStyle(Palette.muted)
                        }
                        .textCase(nil)
                        .padding(.horizontal, 4)
                    }
                }

                Section {
                    VStack(spacing: 14) {
                        HStack(spacing: 24) {
                            Button("Kelola kategori") {
                                showCategorySheet = true
                            }
                            Button("Hapus semua catatan") {
                                confirmClear = true
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(Palette.muted)

                        privacyLink
                    }
                    .buttonStyle(.borderless)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                } footer: {
                    Text("Geser catatan ke kiri untuk menghapus. Tekan lama untuk mengganti kategori.")
                        .font(.footnote)
                        .foregroundStyle(Palette.muted)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(.compact)
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.immediately)
        }
    }

    private var emptyState: some View {
        let isNew = store.items.isEmpty
        return VStack(spacing: 6) {
            Spacer()
            Image(systemName: isNew ? "tray" : "calendar.badge.clock")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(Palette.faint)
                .padding(.bottom, 8)
            Text(isNew ? "Belum ada catatan" : "Tidak ada catatan di periode ini")
                .font(.headline)
                .foregroundStyle(Palette.ink)
            Text(isNew ? "Ketik nominal di atas, lalu pilih kategorinya." : "Pilih periode lain di bagian atas.")
                .font(.subheadline)
                .foregroundStyle(Palette.muted)
            Spacer()
            Spacer()
            privacyLink
                .padding(.bottom, 12)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { inputFocused = false }
    }

    private var privacyLink: some View {
        Link("Kebijakan privasi", destination: AppInfo.privacyPolicyURL)
            .font(.footnote)
            .foregroundStyle(Palette.muted)
            .underline()
    }

    private func row(_ spend: Spend) -> some View {
        let choice = store.choice(for: spend)
        // Kategori buatan sendiri yang sudah dihapus: tetap tampilkan namanya
        let deletedName = choice == nil ? spend.customCategoryName : nil
        let icon = choice?.icon ?? (deletedName != nil ? "tag" : "circle.dashed")
        let title = choice?.title ?? deletedName ?? "Tanpa kategori"

        return HStack(spacing: 12) {
            categoryBadge(icon)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                Group {
                    if spend.timeKnown ?? true {
                        Text(spend.date, format: .dateTime.hour().minute())
                    } else {
                        Text("Tanpa jam")
                    }
                }
                .font(.caption)
                .foregroundStyle(Palette.muted)
            }

            Spacer(minLength: 8)

            Text(Rupiah.text(spend.amount))
                .font(.body.weight(.medium))
                .monospacedDigit()
                .foregroundStyle(Palette.ink)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    private func categoryBadge(_ icon: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: 14, weight: .regular))
            .foregroundStyle(Palette.ink)
            .frame(width: 34, height: 34)
            .background(Palette.fill, in: Circle())
    }

    private func dayTitle(_ day: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(day) { return "Hari ini" }
        if cal.isDateInYesterday(day) { return "Kemarin" }
        return format(
            day,
            cal.isDate(day, equalTo: .now, toGranularity: .year) ? "EEEE, d MMMM" : "EEEE, d MMMM yyyy"
        )
    }

    private func format(_ date: Date, _ pattern: String) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "id_ID")
        f.dateFormat = pattern
        return f.string(from: date)
    }

    /// Contoh: "14-20 Sep 2026", "28 Sep - 4 Okt 2026", "28 Des 2025 - 3 Jan 2026"
    private func formatSpan(_ start: Date, _ endInclusive: Date) -> String {
        let cal = Calendar.current
        if cal.isDate(start, inSameDayAs: endInclusive) {
            return format(start, "d MMM yyyy")
        }
        let endText = format(endInclusive, "d MMM yyyy")
        if cal.isDate(start, equalTo: endInclusive, toGranularity: .month) {
            return "\(format(start, "d"))-\(endText)"
        }
        if cal.isDate(start, equalTo: endInclusive, toGranularity: .year) {
            return "\(format(start, "d MMM")) - \(endText)"
        }
        return "\(format(start, "d MMM yyyy")) - \(endText)"
    }

    // MARK: Pesan "Batalkan"

    @ViewBuilder
    private var toastView: some View {
        if let toast {
            HStack(spacing: 12) {
                Text(toast.message)
                    .font(.subheadline)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(3)
                Spacer(minLength: 0)
                Button("Batalkan") {
                    withAnimation(motion) {
                        toast.undo()
                        self.toast = nil
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.accent)
            }
            .padding(.leading, 16)
            .padding(.trailing, 14)
            .padding(.vertical, 14)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Palette.shadow, radius: 16, y: 6)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: Animasi pembuka

    /// Hanya jalan sekali saat aplikasi dibuka. Total durasi sekitar 0,5 detik,
    /// dan kolom nominal tetap bisa langsung diketik.
    private func playEntrance() {
        guard !appeared else { return }

        if reduceMotion {
            // "Kurangi Gerakan" aktif: tampilkan langsung tanpa animasi
            appeared = true
            revealTotal = true
            return
        }

        appeared = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(60))
            withAnimation(.smooth(duration: 0.45)) {
                revealTotal = true
            }
        }
    }

    // MARK: Aksi

    private func add(_ choice: CategoryChoice) {
        let amount = inputAmount
        guard amount > 0 else { return }

        let spend: Spend
        var message: String

        if let day = pickedDate {
            // Catatan untuk tanggal lain: pakai tanggal pilihan, jam sekarang
            // hanya untuk urutan, dan jamnya tidak ditampilkan.
            let date = combine(day: day, withTimeOf: .now)
            spend = withAnimation(motion) {
                store.add(amount, choice: choice, on: date, timeKnown: false)
            }
            let title = dayTitle(day)
            let when = title == "Kemarin" ? "kemarin" : title
            message = "\(choice.title) \(Rupiah.text(amount)) dicatat untuk \(when)"
        } else {
            spend = withAnimation(motion) {
                store.add(amount, choice: choice, on: .now, timeKnown: true)
            }
            message = "\(choice.title) \(Rupiah.text(amount)) dicatat"
        }

        if let range, !range.contains(spend.date) {
            message += ". Tidak tampil karena di luar periode yang dipilih."
        }

        input = ""
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        showToast(message) {
            store.remove(spend)
        }
    }

    private func combine(day: Date, withTimeOf time: Date) -> Date {
        let cal = Calendar.current
        let t = cal.dateComponents([.hour, .minute, .second], from: time)
        return cal.date(
            bySettingHour: t.hour ?? 12,
            minute: t.minute ?? 0,
            second: t.second ?? 0,
            of: day
        ) ?? day
    }

    private func delete(_ spend: Spend) {
        withAnimation(motion) {
            store.remove(spend)
        }
        showToast("\(Rupiah.text(spend.amount)) dihapus") {
            store.restore([spend])
        }
    }

    private func clearAll() {
        let old = withAnimation(motion) { store.removeAll() }
        showToast("Semua catatan dihapus") {
            store.restore(old)
        }
    }

    private func showToast(_ message: String, undo: @escaping () -> Void) {
        let newToast = Toast(message: message, undo: undo)
        withAnimation(motion) { toast = newToast }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(5))
            if toast?.id == newToast.id {
                withAnimation(motion) { toast = nil }
            }
        }
    }
}

// MARK: - Efek muncul (animasi pembuka)

/// Memudar masuk sambil naik sedikit dan menajam dari blur tipis.
struct EntranceEffect: ViewModifier {
    let visible: Bool
    let delay: Double
    let animated: Bool

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 10)
            .blur(radius: visible ? 0 : 4)
            .animation(animated ? .smooth(duration: 0.4).delay(delay) : nil, value: visible)
    }
}

private extension View {
    func entrance(_ visible: Bool, delay: Double, animated: Bool) -> some View {
        modifier(EntranceEffect(visible: visible, delay: delay, animated: animated))
    }
}

// MARK: - Efek tekan tombol

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PressableBody(configuration: configuration)
    }

    private struct PressableBody: View {
        let configuration: ButtonStyleConfiguration
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @Environment(\.isEnabled) private var isEnabled

        init(configuration: ButtonStyleConfiguration) {
            self.configuration = configuration
        }

        var body: some View {
            configuration.label
                .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
                .opacity(configuration.isPressed ? 0.8 : (isEnabled ? 1 : 0.5))
                .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
        }
    }
}

// MARK: - Tambah & kelola kategori

struct CategorySheet: View {
    @ObservedObject var store: SpendStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var icon = CustomCategory.icons[0]
    @FocusState private var nameFocused: Bool

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    init(store: SpendStore) {
        _store = ObservedObject(wrappedValue: store)
    }

    private var trimmed: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isDuplicate: Bool {
        !trimmed.isEmpty && store.isNameTaken(trimmed)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nama kategori", text: $name, prompt: Text("Contoh: Kopi, Bensin, Pulsa"))
                        .focused($nameFocused)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .onSubmit(save)
                        .onChange(of: name) { _, newValue in
                            if newValue.count > 24 { name = String(newValue.prefix(24)) }
                        }

                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(CustomCategory.icons, id: \.self) { symbol in
                            let selected = icon == symbol
                            Button {
                                icon = symbol
                            } label: {
                                Image(systemName: symbol)
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundStyle(selected ? Palette.onAccent : Palette.ink)
                                    .frame(width: 40, height: 40)
                                    .background(selected ? Palette.accent : Palette.fill, in: Circle())
                            }
                            .buttonStyle(PressableStyle())
                            .accessibilityAddTraits(selected ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 6)

                    Button("Simpan kategori", action: save)
                        .fontWeight(.semibold)
                        .disabled(trimmed.isEmpty || isDuplicate)
                } header: {
                    Text("Kategori baru")
                } footer: {
                    if isDuplicate {
                        Text("Nama ini sudah dipakai. Coba nama lain.")
                            .foregroundStyle(Color(uiColor: .systemRed))
                    } else {
                        Text("Kategori baru langsung masuk 3 pilihan teratas saat kamu mengetik nominal.")
                    }
                }

                if !store.customCategories.isEmpty {
                    Section {
                        ForEach(store.customCategories) { category in
                            Label {
                                Text(category.name)
                            } icon: {
                                Image(systemName: category.icon)
                                    .foregroundStyle(Palette.ink)
                            }
                        }
                        .onDelete { offsets in
                            store.deleteCustomCategories(at: offsets)
                        }
                    } header: {
                        Text("Kategori buatanmu")
                    } footer: {
                        Text("Geser ke kiri untuk menghapus. Catatan lama tetap menampilkan nama kategorinya.")
                    }
                }
            }
            .navigationTitle("Kategori")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Selesai") { dismiss() }
                }
            }
        }
        .tint(Palette.accent)
    }

    private func save() {
        guard !trimmed.isEmpty, !isDuplicate else { return }
        store.addCustomCategory(name: trimmed, icon: icon)
        name = ""
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}

// MARK: - Pilih rentang tanggal

struct RangeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var start: Date
    @State private var end: Date
    private let onApply: (Date, Date) -> Void

    init(start: Date, end: Date, onApply: @escaping (Date, Date) -> Void) {
        _start = State(initialValue: start)
        _end = State(initialValue: end)
        self.onApply = onApply
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Dari", selection: $start, in: ...end, displayedComponents: .date)
                    DatePicker("Sampai", selection: $end, in: min(start, .now)...Date.now, displayedComponents: .date)
                } footer: {
                    Text("Total pengeluaran dan riwayat akan menampilkan catatan di antara dua tanggal ini, termasuk tanggal awal dan akhirnya.")
                }
            }
            .environment(\.locale, Locale(identifier: "id_ID"))
            .navigationTitle("Pilih tanggal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Terapkan") {
                        onApply(start, end)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .tint(Palette.accent)
        .presentationDetents([.medium])
    }
}

#Preview {
    ContentView()
}
