//
//  ListController.swift
//  NoticeApp
//
//  Created by zino-mac on 2020/03/13.
//  Copyright © 2020 zino-mac. All rights reserved.
//

import UIKit

//JSON 객체 하나를 대응할 클래스 정의
class Notice:Decodable{
    var notice_id:Int
    var title:String
    var writer:String
    var content:String
    var regdate:String
    var hit:Int
    
    init(notice_id:Int, title:String, writer:String, content:String,regdate:String,hit:Int){
        self.notice_id = notice_id
        self.title = title
        self.writer = writer
        self.content = content
        self.regdate = regdate
        self.hit = hit
    }
}

//JSON 배열 하나를 대응할 클래스 정의
class NoticeList:Decodable{
    var list:[Notice]=[Notice]()
}

class ListController: UITableViewController {
    var noticeArray:Array<Notice> = Array<Notice>()
    
    @IBAction func btnRefresh(_ sender: Any) {
        loadData()
    }
    
    //웹서버에서 데이터 가져오기 !! , 비동기로 가져와야 한다
    //메인 실행부는 UI처리와 이벤트처리를 담당하기 때문에, 절대로
    //루프나 스트림으로 인한 대기상태에 빠지게 해서는 안된다!!! 앱이 멈춘다
    //비동기 객체 URLSession
    func loadData(){
        let url = URL(string: "http://localhost:7777/notice/list")!
        let urlSession = URLSession.shared
        //{(파라미터) -> 반환형 in 로직}
        
        let task = urlSession.dataTask(with: url, completionHandler: {
            (data, response, error) in
                //여기에 로직~~~
                //테이블뷰 UI다시 새로고침~~
                //UI를 갱신하는 권한은 오직 메인실행부에만 있으므로, 이 영역에서 화면갱신
                //불가능하다... 해결책) 메인 실행부에게 갱신을 부탁!!
                let str = String(data: data!, encoding: String.Encoding.utf8)
            
                print("서버에서 받은 데이터", str!)
            
                //JSON을 파싱하여 클래스 인스턴스에 담은 후 다시 배열에 담자!!
                //테이블에서 접근하기 좋게 하려고...
                let parser = JSONDecoder() //제이슨 해석자!!
                
                do{
                    //파싱이 완료된 시점에 반환되는 것은?? NoticeList 클래스의
                    //인스턴스이다!!
                    var noticeList = try parser.decode(NoticeList.self, from: data!)
                    //Notice 인스턴스들을 다시 배열에 담아놓자!!
                    //혹시 존재하는 데이터가 있다면 모두 지운다
                    self.noticeArray.removeAll()
                    
                    for obj in noticeList.list{
                        self.noticeArray.append(obj)
                    }
                    
                    //테이블뷰 갱신 요청!!
                    //메인 실행부에게 갱신을 요청
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }catch{
                    print(error)
                }
            })
        
        task.resume() //비동기 요청 시작!!!
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadData()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return noticeArray.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "myCell", for: indexPath)

        // Configure the cell...
        let notice = noticeArray[indexPath.row] //배열에서 요소 꺼내기
        
        cell.textLabel?.text = notice.title
        
        return cell
    }
    

    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            //모델을 삭제 ( 데이터 제거 )
            //곧 지워질 녀석!!
            var notice = noticeArray[indexPath.row]
            
            noticeArray.remove(at: indexPath.row)
            
            //웹서버에 삭제를 요청한다!
            requestDel2(notice_id:notice.notice_id)
            
            //뷰를 삭제 ( 디자인 제거)
            tableView.deleteRows(at: [indexPath], with: .fade)
            
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
    //웹에 삭제 요청하기!!
    func requestDel(notice_id:Int){
        //요청 주소 객체 URL에 파라미터를 추가할 수 잇는 객체
        var urlComponent = URLComponents(string:"http://localhost:7777/notice/del")!
        
        //파라미터 만들기!!
        //파라미터 한쌍을 표현한 객체 URLQueryItem 이다!!
        //3쌍을 만들고 싶다면 이 객체를 3개만들면 된다!
        var params = [URLQueryItem]() //Empty
        
        params.append(URLQueryItem(name: "notice_id", value: String(notice_id)))
        
        params.append(URLQueryItem(name: "test", value: "연습"))

        //완성된 파라미터를 URL객체에 탑재!!
        urlComponent.queryItems = params
        
        //GET/POST 여부를 지정
        var urlRequest = URLRequest(url: urlComponent.url!)
        
        urlRequest.httpMethod = "GET"
        
        //비동기로 요청 시작!!
        let urlSession = URLSession.shared
        urlSession.dataTask(with: urlRequest, completionHandler: {
            (data, response, error) in
            // 처리 로직!!
            /*
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            */
        })
    }

    
    func requestDel2(notice_id:Int){
        var urlComponent = URLComponents(string: "http://localhost:7777/notice/del")!
        
        //딕셔너리 생성
        var params = [URLQueryItem]()
        
        params.append(URLQueryItem(name: "notice_id", value: String(notice_id)))

        urlComponent.queryItems = params//파라미터 적용
        
        var urlRequest = URLRequest(url: urlComponent.url!)
        urlRequest.httpMethod = "GET"
        
        let urlSession = URLSession.shared
        urlSession.dataTask(with: urlRequest, completionHandler: {(data, response, error) in
            DispatchQueue.main.async {
                self.tableView.reloadData()
                
            }
            }).resume()
    }
    
    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
