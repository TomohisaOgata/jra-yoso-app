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
    @State private var activeRace: Race?
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
                        CuteHorseView().frame(width:220,height:175)
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
                            Button("🏇 出走する") { activeRace = race }.buttonStyle(.borderedProminent)
                        }.padding(.vertical,6)
                    }
                }
                Section("結果") { Text(farm.message) }
                Section { Text("開催日は実際の日程を参考にした固定データです。対戦相手・勝敗・タイプ分類はゲーム独自のものです。") }
            }.navigationTitle("🏆 レース")
        .sheet(item:$activeRace) { race in RaceAnimationView(race:race,horseName:farm.name) { farm.race(race) } }
        }
    }
}

struct CuteHorseView: View {
    var body: some View {
        ZStack {
            Ellipse().fill(.green.opacity(0.15)).frame(width:215,height:22).offset(y:73)
            // Body, neck and head are drawn in SwiftUI, so no external image is required.
            Ellipse().fill(Color(red:0.68,green:0.36,blue:0.18)).frame(width:145,height:95).offset(x:5,y:17)
            RoundedRectangle(cornerRadius:30).fill(Color(red:0.73,green:0.40,blue:0.20))
                .frame(width:62,height:110).rotationEffect(.degrees(-24)).offset(x:-50,y:-21)
            Ellipse().fill(Color(red:0.76,green:0.43,blue:0.23)).frame(width:85,height:80).offset(x:-78,y:-51)
            Ellipse().fill(.brown).frame(width:22,height:44).rotationEffect(.degrees(-25)).offset(x:-107,y:-100)
            Ellipse().fill(.brown).frame(width:22,height:44).rotationEffect(.degrees(20)).offset(x:-56,y:-103)
            Ellipse().fill(.white).frame(width:21,height:24).offset(x:-98,y:-59)
            Circle().fill(.black).frame(width:11).offset(x:-100,y:-59)
            Circle().fill(.white).frame(width:4).offset(x:-103,y:-63)
            Ellipse().fill(Color(red:0.93,green:0.72,blue:0.59)).frame(width:50,height:35).offset(x:-107,y:-25)
            Circle().fill(.brown).frame(width:5).offset(x:-122,y:-28)
            Circle().fill(.pink.opacity(0.55)).frame(width:19).offset(x:-69,y:-28)
            ForEach(0..<4,id:\.self) { i in
                RoundedRectangle(cornerRadius:9).fill(Color(red:0.57,green:0.28,blue:0.14))
                    .frame(width:20,height:67).offset(x:CGFloat(i)*35-38,y:62)
            }
            Text("〰️").font(.system(size:37)).rotationEffect(.degrees(-50)).offset(x:95,y:0)
            Text("💕").font(.title2).offset(x:73,y:-85)
        }.accessibilityLabel("かわいい茶色の愛馬")
    }
}

struct RaceAnimationView: View {
    let race: Race
    let horseName: String
    let onFinish: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var progress = 0.0
    @State private var finished = false
    @State private var commentary = "まもなくスタート！"
    var body: some View {
        VStack(spacing:20) {
            Text("🏁 \(race.name)").font(.title2.bold())
            Text("\(race.type.icon) \(race.type.rawValue)型 · \(race.distance)")
            GeometryReader { geo in
                VStack(spacing:15) {
                    ForEach(0..<4,id:\.self) { i in
                        ZStack(alignment:.leading) {
                            RoundedRectangle(cornerRadius:12).fill(Color.green.opacity(0.15)).frame(height:70)
                            Text(i == 0 ? "🐴" : ["🐎","🐎","🐎"][i-1])
                                .font(.system(size:42))
                                .offset(x:CGFloat(progress * Double(max(0,geo.size.width-65)) * (i == 0 ? 1 : [0.94,0.97,0.91][i-1])))
                        }
                    }
                }
            }.frame(height:350)
            Text(commentary).font(.headline)
            if finished {
                Button("結果を見る") { dismiss() }.buttonStyle(.borderedProminent)
            } else {
                ProgressView(value:progress)
            }
        }.padding()
        .onAppear {
            withAnimation(.linear(duration:5)) { progress=1 }
            Task {
                try? await Task.sleep(for:.seconds(2))
                commentary="第3コーナー！ 愛馬が前へ！"
                try? await Task.sleep(for:.seconds(2))
                commentary="最後の直線！ ゴールは目前！"
                try? await Task.sleep(for:.seconds(1))
                onFinish()
                commentary="🏆 レース終了！"
                finished=true
            }
        }
    }
}
