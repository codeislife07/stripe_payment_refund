import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:stripe_payment_refund/stripe_config.dart';

void main() {
  Stripe.publishableKey=secret_key;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Stripe payment and refund"),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: (){
              makepayment(amount:"100",currency:"INR");
            }, child: Text("Pay Now")),
            ElevatedButton(onPressed: (){
              refund(amount:"100");
            }, child: Text("Refund Amount")),
            SizedBox(height: 100,),
            Text(paymentIntentData.toString())
          ],
        ),
      ),
    );
  }

  Map<String,dynamic> paymentIntentData={};
  Future<void> makepayment({required String amount, required String currency}) async {
    try{
      paymentIntentData=await createPaymentIntent(amount,currency);
      setState(() { });
      if(paymentIntentData!=null){
        await Stripe.instance.initPaymentSheet(
            paymentSheetParameters: SetupPaymentSheetParameters(
              googlePay: PaymentSheetGooglePay(merchantCountryCode: "IN"),
              merchantDisplayName: "Coding Is Life",
              customerId: paymentIntentData['customer'],
              paymentIntentClientSecret: paymentIntentData['client_secret'],
              customerEphemeralKeySecret: paymentIntentData['ephemeralkey']
            )
        );
        displayPaymentSheet();
      }

    }catch(e){
      print("EXCEPTION=====$e");
    }
  }

  createPaymentIntent(String amount, String currency) async {
    try{
      Map<String,String> body={
        'amount':calculateAmount(amount),
        "currency":currency,
        'payment_method_types[]':'card'
      };
      var response=await http.post(Uri.parse(""
          "https://api.stripe.com/v1/payment_intents"
          ""),
        body: body,
        headers: {
          "Authorization":"Bearer $client_key",
          "Content-Type":"application/x-www-form-urlencoded"
        }
        );
      return jsonDecode(response.body);
    }catch(e){

    }
  }

  Future<void> displayPaymentSheet() async {
    try{
      await Stripe.instance.presentPaymentSheet();
      print("Success payment");
    }catch(e){
      print("EXCEPTION=====$e");
    }
  }

  calculateAmount(String amount) {
    final amountValue=(int.parse(amount))*100;
    return amountValue.toString();
  }

  Future<void> refund({required String amount}) async {
    var response=await http.post(
        Uri.parse("https://api.stripe.com/v1/refunds"),
        headers: {
          "Authorization":"Bearer $client_key",
          "Content-Type":"application/x-www-form-urlencoded"
        },
      body: {
          "payment_intent":"${paymentIntentData['id']}",
          "amount":calculateAmount(amount),
      }
    );
    print("Response of refund amount ${response.body}");
    //error if refund not done
  }

}
