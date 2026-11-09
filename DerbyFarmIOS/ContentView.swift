import SwiftUI

enum HorseType: String, CaseIterable, Codable {
    case speed = "スピード", power = "パワー", stamina = "スタミナ"
    var icon: String { switch self { case .speed: "⚡"; case .power: "🔥"; case .stamina: "🌿" } }
    func beats(_ other: HorseType) -> Bool {
        (self == .speed && other == .stamina) ||
        (self == .stamina && other == .power) ||
        (self == .power && other == .speed)
    }
}
struct Race: Identifiable {
    let id: String
    let date: String
    let name: String
    let type: HorseType
    let distance: String
}
@MainActor final class Farm: ObservableObject {
    @Published var name = "サクラブレイズ"
    @Published var type: HorseType = .speed
    @Published var speed = 55
    @Published var power = 50
    @Published var stamina = 50
    @Published var energy = 100
    @Published var affection = 3
    @Published var coins = 3000
    @Published var wins = 0
    @Published var message = "今日も元気いっぱい！"
    init() { load() }
    func save() {
        let values: [String:Any] = ["name":name,"type":type.rawValue,"speed":speed,"power":power,"stamina":stamina,"energy":energy,"affection":affection,"coins":coins,"wins":wins]
        UserDefaults.standard.set(values,forKey:"derby-farm-save")
    }
    func load() {
        guard let v = UserDefaults.standard.dictionary(forKey:"derby-farm-save") else { return }
        name=v["name"] as? String ?? name
        type=HorseType(rawValue:v["type"] as? String ?? "") ?? type
        speed=v["speed"] as? Int ?? speed
        power=v["power"] as? Int ?? power
        stamina=v["stamina"] as? Int ?? stamina
        energy=v["energy"] as? Int ?? energy
        affection=v["affection"] as? Int ?? affection
        coins=v["coins"] as? Int ?? coins
        wins=v["wins"] as? Int ?? wins
    }
    func train(_ kind: HorseType) {
        guard energy >= 15 else { message="疲れているので休養しよう"; return }
        energy -= 15
        switch kind { case .speed: speed += 4; case .power: power += 4; case .stamina: stamina += 4 }
        message="\(kind.icon) \(kind.rawValue)が4上がった！"
        save()
    }
    func rest() { energy=min(100,energy+40); message="ゆっくり休んで元気になった！"; save() }
    func pet() { affection=min(5,affection+1); message="うれしそうに尻尾を振っている💕"; save() }
    func race(_ race: Race) {
        guard energy >= 20 else { message="出走には体力20以上が必要です"; return }
        energy -= 20
        let base = Double(speed+power+stamina)/3
        let bonus = race.type == type ? 20.0 : (type.beats(race.type) ? 12.0 : -12.0)
        let score = base+bonus+Double(Int.random(in:-20...20))
        let first = score >= 73
        if first { wins += 1; coins += 1200 }
        else { coins += 100 }
        message="\(race.name)：\(first ? "🏆 優勝！ 賞金1200" : "健闘！ 賞金100")"
        save()
    }
}
struct ContentView: View {
    @StateObject private var farm = Farm()
    @State private var tab = 0
    private let races: [Race] = [
        .init(id:"2026-11-15",date:"11/15",name:"エリザベス女王杯",type:.stamina,distance:"芝2200m"),
        .init(id:"2026-11-22",date:"11/22",name:"マイルチャンピオンシップ",type:.speed,distance:"芝1600m"),
        .init(id:"2026-11-29",date:"11/29",name:"ジャパンカップ",type:.stamina,distance:"芝2400m"),
        .init(id:"2026-12-06",date:"12/6",name:"チャンピオンズカップ",type:.power,distance:"ダ1800m"),
        .init(id:"2026-12-27",date:"12/27",name:"有馬記念",type:.stamina,distance:"芝2500m")
    ]
    var body: some View {
        TabView(selection:$tab) {
            home.tabItem { Label("愛馬",systemImage:"heart.fill") }.tag(0)
            training.tabItem { Label("調教",systemImage:"figure.run") }.tag(1)
            racing.tabItem { Label("レース",systemImage:"flag.checkered") }.tag(2)
        }.tint(.pink)
    }
    private var home: some View {
        ScrollView {
            VStack(spacing:16) {
                Text("🌸 ダービー牧場 🌸").font(.largeTitle.bold())
                TextField("馬名",text:$farm.name).textFieldStyle(.roundedBorder).padding(.horizontal)
                    .onSubmit { farm.save() }
                ZStack {
                    RoundedRectangle(cornerRadius:28).fill(LinearGradient(colors:[.pink.opacity(0.18),.mint.opacity(0.35)],startPoint:.top,endPoint:.bottom))
                    VStack(spacing:0) {
                        Text("🌸  🌼  🌸").font(.title)
                        Text("🐴").font(.system(size:130))
                        Text("💕 かわいい愛馬 💕").font(.headline)
                    }
                }.frame(height:250).padding(.horizontal)
                Text("\(farm.type.icon) \(farm.type.rawValue)タイプ").font(.title3.bold())
                HStack { Text("💗 親愛度 \(String(repeating:"♥",count:farm.affection))"); Spacer(); Text("💰 \(farm.coins)") }
                    .padding(.horizontal)
                stat("⚡ スピード",farm.speed)
                stat("🔥 パワー",farm.power)
                stat("🌿 スタミナ",farm.stamina)
                stat("体力",farm.energy)
                Text("🏆 \(farm.wins)勝").font(.title3)
                Button("🥕 なでなでする") { farm.pet() }.buttonStyle(.borderedProminent).tint(.pink)
                Text(farm.message).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }.padding(.vertical)
        }
    }
    private func stat(_ label:String,_ value:Int) -> some View {
        HStack {
            Text(label).frame(width:120,alignment:.leading)
            ProgressView(value:Double(min(100,value)),total:100)
            Text("\(value)").monospacedDigit().frame(width:35)
        }.padding(.horizontal)
    }
    private var training: some View {
        VStack(spacing:20) {
            Text("🏋️ 調教").font(.largeTitle.bold())
            Text("体力 \(farm.energy)/100")
            ForEach(HorseType.allCases,id:\.self) { kind in
                Button("\(kind.icon) \(kind.rawValue)調教（体力-15）") { farm.train(kind) }
                    .buttonStyle(.borderedProminent)
            }
            Button("🌱 放牧・休養（体力+40）") { farm.rest() }.buttonStyle(.bordered)
            Text("タイプ変更")
            Picker("タイプ",selection:$farm.type) {
                ForEach(HorseType.allCases,id:\.self) { kind in Text(kind.rawValue).tag(kind) }
            }.pickerStyle(.segmented).onChange(of:farm.type) { _,_ in farm.save() }
            Text("⚡ → 🌿 → 🔥 → ⚡").font(.headline)
            Text(farm.message).multilineTextAlignment(.center)
            Spacer()
        }.padding()
    }
    private var racing: some View {
        NavigationStack {
            List {
                Section("2026年 JRA主要GI・ゲーム内レース") {
                    ForEach(races) { race in
                        VStack(alignment:.leading,spacing:8) {
                            Text("\(race.date)  \(race.name)").font(.headline)
                            Text("\(race.distance) · \(race.type.icon) \(race.type.rawValue)型").foregroundStyle(.secondary)
                            Button("🏇 出走する") { farm.race(race) }.buttonStyle(.borderedProminent)
                        }.padding(.vertical,6)
                    }
                }
                Section("結果") { Text(farm.message) }
                Section { Text("開催日は実際の日程を参考にした固定データです。対戦相手・勝敗・タイプ分類はゲーム独自のものです。") }
            }.navigationTitle("🏆 レース")
        }
    }
}
