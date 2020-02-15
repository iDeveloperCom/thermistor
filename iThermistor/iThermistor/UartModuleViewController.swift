import UIKit
import CoreBluetooth
import Charts

class UartModuleViewController: UIViewController, ChartViewDelegate {
    
    @IBOutlet var tempChartView: LineChartView!
    @IBOutlet var windChartView: LineChartView!
    @IBOutlet var tempSlider: UISlider!
    @IBOutlet var windSlider: UISlider!
    @IBOutlet var timeSlider: UISlider!
    @IBOutlet var tempLabel: UILabel!
    @IBOutlet var windLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    
    var maxTemp: Double = 0
    var minTemp: Double = 0
    var maxWind: Double = 0
    var minWind: Double = 0

    var TIMERANGE: Double = 900
    var TEMPRANGE: Double = 20
    var WINDRANGE: Double = 10

    var tempDataIndex: Double = 0
    var windDataIndex: Double = 0

    var averageTemperature: AverageBuffer = AverageBuffer(with: 1000)

    var startUpTemp: Bool = true
    var startUpWind: Bool = true

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        updateIncomingData();
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "DISCONNECTED"), object: nil , queue: nil){_ in
            self.dismiss(animated: true, completion: nil)
        }
        initTempDataChart()
        initWindDataChart()
        
        let tempGesture = UIPinchGestureRecognizer(target: self, action: #selector(scaleTemp(_:)))
        tempChartView.addGestureRecognizer(tempGesture)
        let windGesture = UIPinchGestureRecognizer(target: self, action: #selector(scaleWind(_:)))
        windChartView.addGestureRecognizer(windGesture)
        
        recalculateAxis()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    func setMaxMin() {
        tempChartView.xAxis.axisMinimum = 0
        tempChartView.xAxis.axisMaximum = TIMERANGE
        tempChartView.xAxis.axisRange =  TIMERANGE
        tempChartView.setVisibleXRange(minXRange: Double(0), maxXRange: Double(TIMERANGE))
        tempChartView.xAxis.gridLineDashLengths = [5, 5]
        tempChartView.xAxis.gridLineDashPhase = 0

        windChartView.xAxis.axisMinimum = 0
        windChartView.xAxis.axisMaximum = TIMERANGE
        windChartView.xAxis.axisRange =  TIMERANGE
        windChartView.setVisibleXRange(minXRange: Double(0), maxXRange: Double(TIMERANGE))
        windChartView.xAxis.gridLineDashLengths = [5, 5]
        windChartView.xAxis.gridLineDashPhase = 0
    }

    func initTempDataChart() {
        tempChartView.delegate = self
        
        tempChartView.chartDescription?.enabled = false
        tempChartView.dragEnabled = false
        tempChartView.setScaleEnabled(false)
        tempChartView.autoScaleMinMaxEnabled = false
        tempChartView.pinchZoomEnabled = false
        tempChartView.rightAxis.enabled = false
        setMaxMin()
        
        tempChartView.leftAxis.removeAllLimitLines()
        tempChartView.leftAxis.axisRange = TEMPRANGE
        tempChartView.leftAxis.axisMaximum = TEMPRANGE
        tempChartView.leftAxis.axisMinimum = 0
        tempChartView.leftAxis.gridLineDashLengths = [5, 5]
        tempChartView.leftAxis.drawLimitLinesBehindDataEnabled = false
        tempChartView.leftAxis.drawTopYLabelEntryEnabled = false
        tempChartView.leftAxis.drawLimitLinesBehindDataEnabled = true
        tempChartView.animate(xAxisDuration: 2.5)

        addTempDataSet()
    }

    func initWindDataChart() {
        windChartView.delegate = self
        
        windChartView.chartDescription?.enabled = false
        windChartView.dragEnabled = false
        windChartView.setScaleEnabled(false)
        windChartView.autoScaleMinMaxEnabled = false
        windChartView.pinchZoomEnabled = false
        windChartView.rightAxis.enabled = false
        setMaxMin()

        windChartView.leftAxis.removeAllLimitLines()
        windChartView.leftAxis.axisRange = WINDRANGE
        windChartView.leftAxis.axisMaximum = WINDRANGE
        windChartView.leftAxis.axisMinimum = 0
        windChartView.leftAxis.gridLineDashLengths = [5, 5]
        windChartView.leftAxis.drawLimitLinesBehindDataEnabled = true
        windChartView.leftAxis.drawTopYLabelEntryEnabled = false
        windChartView.leftAxis.drawLimitLinesBehindDataEnabled = true
        windChartView.animate(xAxisDuration: 2.5)

        addWindDataSet()
    }

    func addTempDataSet() {
        self.tempDataIndex = 0
        self.tempChartView.data?.clearValues()
        self.tempChartView.moveViewToX(0)

        let set1: LineChartDataSet = LineChartDataSet(entries:[ChartDataEntry(x: Double(0), y: Double(0))], label: "Far Temperature °C")
        set1.drawCirclesEnabled = false
        set1.setColor(UIColor.red)
        set1.mode = .horizontalBezier

        let set2: LineChartDataSet = LineChartDataSet(entries:[ChartDataEntry(x: Double(0), y: Double(0))], label: "Near Temperature °C")
        set2.drawCirclesEnabled = false
        set2.setColor(UIColor.magenta)
        set2.mode = .horizontalBezier

        self.tempChartView.data = LineChartData(dataSets: [set1, set2])
        self.tempChartView.data?.setDrawValues(false)
    }
    
    func addWindDataSet() {
        self.windDataIndex = 0
        self.windChartView.data?.clearValues()
        self.windChartView.moveViewToX(0)

        let set1: LineChartDataSet = LineChartDataSet(entries:[ChartDataEntry(x: Double(0), y: Double(0))], label: "Far Wind m/s")
        set1.drawCirclesEnabled = false
        set1.setColor(UIColor.green)
        set1.mode = .horizontalBezier

        let set2: LineChartDataSet = LineChartDataSet(entries:[ChartDataEntry(x: Double(0), y: Double(0))], label: "Near Wind m/s")
        set2.drawCirclesEnabled = false
        set2.setColor(UIColor.blue)
        set2.mode = .horizontalBezier

        self.windChartView.data = LineChartData(dataSets: [set1, set2])
        self.windChartView.data?.setDrawValues(false)
    }
    
    func updateIncomingData () {
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "TEMP"), object: nil , queue: nil){
            notification in
            let bytes = (notification.object as! Data).bytes
            let t1 = [bytes[0],bytes[1]]
            let t2 = [bytes[2],bytes[3]]

            let temp1 = t1.data.intValue()
            let temp2 = t2.data.intValue()
            let f1 : Double = Double(temp1) / Double(100)
            let f2 : Double = Double(temp2) / Double(100)
            self.averageTemperature.append(newval: f1)
            var dataIndex = self.tempDataIndex + 0.5
            self.tempDataIndex = self.tempDataIndex + 0.5

            DispatchQueue.main.async { [weak self] in
                if self?.tempDataIndex == self?.TIMERANGE {
                    self?.addTempDataSet()
                    if let di = self?.tempDataIndex {
                        dataIndex = di
                    }
                }
                self?.tempChartView.moveViewToX(Double(dataIndex))
                self?.tempChartView.data?.addEntry(ChartDataEntry(x: Double(dataIndex), y: f1), dataSetIndex: 0)
                self?.tempChartView.data?.addEntry(ChartDataEntry(x: Double(dataIndex), y: f2), dataSetIndex: 1)
                self?.tempChartView.notifyDataSetChanged()
            }
            if self.startUpTemp {
                self.startUpTemp = false
                self.recalculateAxis()
            }
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "WIND"), object: nil , queue: nil){
            notification in
            let bytes = (notification.object as! Data).bytes
            let t1 = [bytes[0],bytes[1]]
            let t2 = [bytes[2],bytes[3]]
            let wind1 = t1.data.intValue()
            let wind2 = t2.data.intValue()
            print(" Wind 1 \(wind1)")
            print(" Wind 2 \(wind2)")

            let f1 = self.calcWindMS(for: Double(wind1) / Double(100.0))
            let f2 = self.calcWindMS(for: Double(wind2) / Double(100.0))
            var dataIndex = self.windDataIndex + 0.5
            self.windDataIndex = self.windDataIndex + 0.5

            DispatchQueue.main.async { [weak self] in
                if self?.windDataIndex == self?.TIMERANGE {
                    self?.addWindDataSet()
                    if let di = self?.windDataIndex {
                        dataIndex = di
                    }
                }
                self?.windChartView.moveViewToX(Double(dataIndex))
                self?.windChartView.data?.addEntry(ChartDataEntry(x: Double(dataIndex), y: f1), dataSetIndex: 0)
                self?.windChartView.data?.addEntry(ChartDataEntry(x: Double(dataIndex), y: f2), dataSetIndex: 1)
                self?.windChartView.notifyDataSetChanged()
            }
            if self.startUpWind {
                self.startUpWind = false
                self.recalculateAxis()
            }
        }

    }
    
    private func recalculateAxis() {
        let tempav = averageTemperature.getAverage()
        
        let tempMax = tempav + (TEMPRANGE / 2)
        let tempMin = (tempav - (TEMPRANGE / 2)) > 0 ? (tempav - (TEMPRANGE / 2)) : 0

        tempChartView.leftAxis.axisRange = TEMPRANGE
        tempChartView.leftAxis.axisMaximum = tempMax
        tempChartView.leftAxis.axisMinimum = tempMin

        windChartView.leftAxis.axisRange = WINDRANGE
        windChartView.leftAxis.axisMaximum = WINDRANGE
        windChartView.leftAxis.axisMinimum = 0
    }
    
    private func calcWindMS(for turns: Double) -> Double {
        return turns
        // return (turns * 4) / 60
    }
    
    @IBAction func scaleTemp(_ sender: UIPinchGestureRecognizer) {
        print("Temp Scale = \(sender.scale)");
        TEMPRANGE = round(TEMPRANGE * Double(sender.scale))
        if (TEMPRANGE > maxTemp) {
            TEMPRANGE = maxTemp
        }
        if (TEMPRANGE < minTemp) {
            TEMPRANGE = minTemp
        }
        tempLabel.text = String(TEMPRANGE)
        tempSlider.value = Float(TEMPRANGE)
        recalculateAxis()
    }
    
    @IBAction func scaleWind(_ sender: UIPinchGestureRecognizer) {
        print("Wind Scale = \(sender.scale)");
        WINDRANGE = round(WINDRANGE * Double(sender.scale)) + 1
        windLabel.text = String(WINDRANGE)
        windSlider.value = Float(WINDRANGE)
        recalculateAxis()
    }
    
    @IBAction func valueChanged(sender: Any?) {
        if let sender = sender as! UISlider? {
            let val: Double = round(Double(sender.value))
            if sender.tag == 1 {
                TEMPRANGE = val
                tempLabel.text = String(val)
                recalculateAxis()
            } else
            if sender.tag == 2 {
                WINDRANGE = val + 1
                windLabel.text = String(val)
                recalculateAxis()
            } else
            if sender.tag == 3 {
                TIMERANGE = val
                timeLabel.text = String(round(val))
                setMaxMin()
            }
        }
    }
 }

extension Data {
    
    func intValue() -> Int16 {
       return self.withUnsafeBytes { $0.load(as: Int16.self) }
    }

    var bytes : [UInt8]{
        return [UInt8](self)
    }
}

extension Array where Element == UInt8 {
    var data : Data{
        return Data(self)
    }
}

