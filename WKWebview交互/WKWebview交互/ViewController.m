//
//  ViewController.m
//  WKWebview交互
//
//  Created by 斌 on 2017/6/20.
//  Copyright © 2017年 斌. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>

@interface ViewController ()<WKUIDelegate,WKNavigationDelegate,WKScriptMessageHandler>

@property(nonatomic,weak)WKWebView *webView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    /** 创建原生控件 */
    [self createNativeView];
    /** 创建WKWebView */
    [self createWebView];
    
}

#pragma mark - 原生控件调用js方法 -
- (void)createNativeView{

    UIView *navView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 200)];
    [self.view addSubview:navView];
    navView.backgroundColor = [UIColor blueColor];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(80, 80, 200, 60);
    button.layer.cornerRadius = 5;
    [button setTitle:@"点击调用js方法" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(navButtonAction) forControlEvents:UIControlEventTouchUpInside];
    button.backgroundColor = [UIColor lightGrayColor];
    [navView addSubview:button];
}

- (void)createWebView{
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 200, self.view.frame.size.width, self.view.frame.size.height - 200) configuration:config];
    webView.navigationDelegate = self;
    webView.UIDelegate = self;
    /** 获取网页DOM元素并注入代码 */
    NSString *js = @"document.getElementsByTagName('h2')[0].innerText = '我是ios为h5注入的方法'";
    WKUserScript *script = [[WKUserScript alloc] initWithSource:js injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    [config.userContentController addUserScript:script];
    /** 向网页注册方法监听 */
    [[webView configuration].userContentController addScriptMessageHandler:self name:@"showMessage"];
    [self.view addSubview:webView];
    self.webView = webView;
    
    /** 加载本地index.html文件 */
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
    NSString *htmlString = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    NSURL *url = [[NSURL alloc] initWithString:filePath];
    [self.webView loadHTMLString:htmlString baseURL:url];
    
    /** 加载网页URL */
//    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString: @"https://www.jianshu.com/p/6ec9571a0105"]];
//    [webView loadRequest:request];
}

#pragma mark - 原生调用js里的navButtonAction方法并传入两个参数
- (void)navButtonAction{
    [self.webView evaluateJavaScript:@"navButtonAction('Jonas',25)" completionHandler:^(id _Nullable response, NSError * _Nullable error) {
        NSLog(@"%@",response);
    }];
}

#pragma mark WKNavigationDelegate
// 开始加载
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    // 可以在这里做正在加载的提示动画 然后在加载完成代理方法里移除动画
}

// 网络错误
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    // 在这里可以做错误提示
}

// 网页加载完成
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    //获取js元素内容
    NSString *inputValueJS = @"document.getElementsByTagName('h1')[0].innerText";
    [webView evaluateJavaScript:inputValueJS completionHandler:^(id _Nullable response, NSError * _Nullable error) {
        NSLog(@"value: %@ error: %@", response, error);
    }];
}
    
    
#pragma mark WKUIDelegate

// alert
//此方法作为js的alert方法接口的实现，默认弹出窗口应该只有提示信息及一个确认按钮，当然可以添加更多按钮以及其他内容，但是并不会起到什么作用
//点击确认按钮的相应事件需要执行completionHandler，这样js才能继续执行
////参数 message为  js 方法 alert(<message>) 中的<message>
#pragma mark - 监听js alert弹窗
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler{
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }])];
    [self presentViewController:alertController animated:YES completion:nil];
}

// confirm
//作为js中confirm接口的实现，需要有提示信息以及两个相应事件， 确认及取消，并且在completionHandler中回传相应结果，确认返回YES， 取消返回NO
//参数 message为  js 方法 confirm(<message>) 中的<message>
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler{
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }])];
    
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }])];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

// prompt
//作为js中prompt接口的实现，默认需要有一个输入框一个按钮，点击确认按钮回传输入值
//当然可以添加多个按钮以及多个输入框，不过completionHandler只有一个参数，如果有多个输入框，需要将多个输入框中的值通过某种方式拼接成一个字符串回传，js接收到之后再做处理
//参数 prompt 为 prompt(<message>, <defaultValue>);中的<message>
//参数defaultText 为 prompt(<message>, <defaultValue>);中的 <defaultValue>
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler{
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:prompt message:@"" preferredStyle:UIAlertControllerStyleAlert]; [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = defaultText;
    }];
    
    [alertController addAction:([UIAlertAction actionWithTitle:@"完成" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(alertController.textFields[0].text?:@"");
    }])];
    [self presentViewController:alertController animated:YES completion:nil];
}


#pragma mark WKScriptMessageHandler-监听js传过来的数据

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSLog(@"%@",message.name);// 方法名
    NSLog(@"%@",message.body);// 传递的数据
}
    
    
#pragma mark - 释放监听 -
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"showMessage"];
}


@end
