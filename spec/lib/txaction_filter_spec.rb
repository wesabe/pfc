require 'spec_helper'

describe TxactionFilter do

  it "should filter txactions" do
    test_names = [
      ['VISA-3LL AUTOMOTIVE OF 925-838-3/VISA-3LL AUTOMOTIVE OF 925-838-3889 CA',
       '3LLAUTOMOTIVEOFLAUTOMOTIVEOFCA'],
      ['DEPOSIT - INTERNET ONLINE BANKING 2765035 PAYMENT PAY NO 36-WEBSTE 14-NOV',
       'DEPOSITINTERNETONLINEBANKINGPAYMENTWEBSTE'],
      ['PURCHASE/09-28-06 AMAZON.COM AMZN.COM/BILLWA auth# 762042',
       'AMAZONCOMAMZNCOMBILLWA'],
      ['TRANSFER FROM 1010026062147/11/17                 ONLINE TRNSFR CNF # VY27192102',
       'TRANSFERFROMXXXX2147ONLINETRNSFR'],
      ['TRANSFER TO ACCT 2/Internet Access Oct. 27, 2006 21:02 Ref: 887932',
       'TRANSFERTOACCT2INTERNETACCESS'],
      ['ATM Withdrawal/Dec 29 7:02 Pm #460503 100 CAMBRIDGE SIDE4020500CAMBRIDGE MA ATM Transaction',
        'ATMWITHDRAWALCAMBRIDGESIDECAMBRIDGEMAATMTRANSACTION'],
      ['04/11BANKCARD DEPOSIT -032509250',
       'BANKCARDDEPOSIT'],
      ['FOO BAR 01-19-1971 BAZ 04/26/1971',
       'FOOBARBAZ'],
      ['025STAR ONE ATM WITHDRWL 11-02 #/025STAR ONE ATM WITHDRWL 11-02 #000003684 CUSTOMER 3965 YAHOO 781 1ST AVE SUNNYVALE     CA',
       '025STARONEATMWITHDRWL025STARONEATMWITHDRWLYAHOO7811STAVESUNNYVALECA'],
      ['INSURANCE PREMIUMLIBLIFE    01OCT56456524400C/P',
       'INSURANCEPREMIUMLIBLIFEC'],
      ['IB SUBSCRIPTIONSEPTEMBER2006        903647990',
       'IBSUBSCRIPTION'],
      ['ANDRONICO\'S MARKE 12-31 CUSTOMER 6724 PURCHASE  #150927 BERKELEY        CA',
       'ANDRONICOSMARKEBERKELEYCA'],
      ['AMAZON.COM          AMZN.COM/BI/VTA9RGIM6 MERCHANDISE371705313951001',
       'AMAZONCOMAMZNCOMBIMERCHANDISE'],
      ['AT&T SBC/Reference # 010207',
       'ATTSBC'],
      ['CPC/SCP #273783/ACHAT PDI ---- 8888',
       'CPCSCPACHATPDI'],
      ['EXXONMOBIL26 09988Q19 SOUTH BU/Withdrawal @ EXXONMOBIL26 09988Q19 SOUTH BU VTUS Trace #30517 (eff. date 12/04/2006)',
       'EXXONMOBILQ19SOUTHBUWITHDRAWALEXXONMOBILQ19SOUTHBUVTUSEFFDATE'],
      ['Transfer/Deposit @ CU ONLINE AT-HOME BRANCH Transfer \"STD\" $1,200.00 from share 0 (eff. date 12/04/2006)',
        'TRANSFERDEPOSITCUONLINEATHOMEBRANCHTRANSFERSTDFROMSHARE0EFFDATE'],
      ['Future Shop #70/Idp Purchase 2029',
       'FUTURESHOP70'],
      ['M P* STARBUCKS USA 00025 01/19M P* STAR',
       'MPSTARBUCKSUSA00025PSTAR'],
      ['43013131331035  06/29 #000107844 PURCHASE                   ALBERTSONS/',
       'ALBERTSONS'],
      ['UNKNOWN PAYEE/0000000007971 MELALEUCA     0000 0018  800-282300D',
       'UNKNOWNPAYEEMELALEUCA'],
      ['PTS TO:  12345678901/',
       'PTSTOXXXX8901'],
      ['Withdrawal  @ PERSONAL BRANCH  T/race #510460046 Conf #EARTHLINKINC OPS',
       'WITHDRAWALPERSONALBRANCHTRACEEARTHLINKINCOPS'],
      ['3% OPEN Savings on JetBlue flight/JETBLUE                $157.10',
       'OPENSAVINGSONJETBLUEFLIGHTJETBLUE'],
      ['DIVIDEND FOR 02/01/07 - 02/28/0/ANNUAL PERCENTAGE YIELD EARNED IS   .49% #0005659',
       'DIVIDENDFOR'],
      ['ICA LA SEK      106.50/ICA LA SEK      106.50',
       'ICALASEKICALASEK'],
      ['UNKNOWN PAYEE/TBI 2971.11377-0lucros',
       'UNKNOWNPAYEETBILUCROS'],
      ['CHECK CRD PURCHASE 11/28 ZACHARY/',
       'ZACHARY'],
      ['POS DEBIT 12/30 WA / POS DEBIT 12/30 WAL-MART #0809 OXFORD AL',
       'WAWALMART0809OXFORDAL'],
      ['ING DIRECT       WITHDRAWAL 000000012345678',
       'INGDIRECTWITHDRAWAL5678'],
      ['ING DIRECT       DEPOSIT    XXXXXXXXXXX5678',
       'INGDIRECTDEPOSIT5678'],
      ["AMZN PMTS 866-216-1/24692168093000866082056; 07399;",
       "AMZNPMTS"],
      ["PAYPAL INST XFER 49D2237DSWLRA/PAYPAL INST XFER 49D2237DSWLRA",
       "PAYPALINSTXFER"],
      ["S/LINE 123456789 / SLFIVEWAYS DEN0901",
       'SLINESLFIVEWAYSDEN' ],
      ["Carte 1234567890123456 Retrait Dab Sg 11/06/08 18 H37 Paris Ternes 00904325",
       "CARTERETRAITDABSGPARISTERNES"],
      ["Vir Recu 8847394340 De: Dassault Systemes France Motif: Salaire 006 2008",
       "VIRRECUDEDASSAULTSYSTEMESFRANCEMOTIFSALAIRE"],
      ["7 Eleven 33363 Chicago I / 10/297 Eleven",
        "7ELEVEN33363CHICAGOI7ELEVEN"],
      ["ACH Electronic Credit        Jun/4270 BROOKLYN AC DIRDEP",
       "ACHELECTRONICCREDIT4270BROOKLYNACDIRDEP"],
      ["CHASE CARD SERVICES 1/",   "CHASECARDSERVICES"],
      ["CHASE CARD SERVICES 300/", "CHASECARDSERVICES"]
    ]
    # Please don't add any more test cases here; they are god fucking awful to debug.
    # Instead, add an individual spec for the specific case that you are testing.
    # Thanks.

    test_names.each do |original, filtered|
      assert_equal filtered, TxactionFilter.filter(original)
    end
  end

  it "should filter Natwest (UK) outgoing account transfers so they match" do
    first  = "TO A/C 12345678 / CALL REF.NO. 0527"
    second = "TO A/C 12345678 / CALL REF.NO. 0528"
    other  = "TO A/C 87654321 / CALL REF.NO. 0528"
    f(first).should == f(second)
    f(first).should_not == f(other)
  end

  it "should filter Natwest (UK) incoming account transfers so they match" do
    first  = "FROM A/C 12345678 / CALL REF.NO. 0438"
    second = "FROM A/C 12345678 / CALL REF.NO. 0439"
    other  = "FROM A/C 87654321 / CALL REF.NO. 0439"
    f(first).should == f(second)
    f(first).should_not == f(other)
  end

  it "should filter Natwest (UK) interest payments so they match" do
    first  = "5AUG NET 12345678"
    second = "30NOV NET 12345678"
    other  = "30NOV NET 87654321"
    f(first).should == f(second)
    f(first).should_not == f(other)
  end

  it "should filter exchange rates out of RBC CC memos" do
    f("SERVER BEACH LTD 800-741-9939 TX / 101.00 USD @ 1.0189").
      should == "SERVERBEACHLTDTX"
  end

  it "should filter tx numbers out of RBC checking/savings payments and transfers" do
    # http://fbz1.dev.oak.wesabe.com/fogbugz/default.php?43912
    f("Payment / WWW PAYMENT - 6884").should == f("Payment / WWW PAYMENT - 8864")
    f("Transfer / WWW TRANSFER - 3920").should == f("Transfer / WWW TRANSFER - 3920")
  end

  it "should filter tx numbers out of WaMu debit card purchases" do
    f("KEYSPAN 446/").should == f("KEYSPAN 447/")
  end

  it "should remove amounts from the end of memos from Bank of New Zealand" do
    f("WELLINGTON NZD850").should == "WELLINGTON"
    f("LOWER HUTT NZD25995").should == "LOWERHUTT"
  end

  it "should remove dates from the front of Commerce Bank check card debits" do
    f("CKCD DEBIT  01/09 STARBUCKS USA").should =~ /^STARBUCKSUSA/
    f("CKCD DEBIT  01/09 WAWA 284 0000R").should =~ /^WAWA/
  end

  it "should include the last 4 of account transfers at Millbury Savings Bank" do
    f("TRANSFER TO LOAN     0123456789").should == "TRANSFERTOLOANXXXX6789"
    f("TRANSFER TO LOAN     9876543210").should == "TRANSFERTOLOANXXXX3210"
  end

  it "should differentiate between loans with 3-digit account numbers" do
    f("TRANSFER TO LOAN 143/").should_not == f("TRANSFER TO LOAN 141/")
  end

  it "should filter out Canada Trust confirmation numbers" do
    f("BELL CANADA  Z7L7Q3").should == f("BELL CANADA  Y4Z9L7")
  end

  it "should filter 'D/C SET' stuff from New Era Bank memos" do
    f("Rhodes 101 Stops / D/C Set 22:56 01/31/08 247").should ==
    f("Rhodes 101 Stops / D/C Set 11:52 01/31/08 277")
  end

  it "should filter out Wespac (NZ)'s crazy memos" do
    f("Dunedin WBC ATM / Ref=27-17:01-404,Part=503513841741,Code=8353Cash").should ==
      "DUNEDINWBCATM"
    f("CanterburyQuarantine / Ref=09:31-34606,Part=quarantine,Code=ONE TIME PMT").should ==
      "CANTERBURYQUARANTINE"
  end

  it "should retain the last 4 and personal name for transfers to CHK|SAV|CRD if they exist" do
    f("Online Banking transfer to CHK 1234 Conf# 123456789; Smith, Bob").should == "ONLINEBANKINGTRANSFERTOCHK1234SMITHBOB"
    f("Online Banking transfer to CHK 12345678").should == "ONLINEBANKINGTRANSFERTOCHK5678"
    f("Online Banking transfer to CHK").should == "ONLINEBANKINGTRANSFERTOCHK"
  end

  it "should filter CHECKPAYMTs to include merchant name and check number but not ref number" do
    f("CHECKPAYMTOLD NAVY 5958").should == "CHECKPAYMTOLDNAVY"
    f("CHECKPAYMT AETNA RX HD/CHECK # 557").should == "CHECKPAYMTAETNARXHDCHECK557"
    f("HSBC AUTO CA ARC/CHECK # 3183").should == "HSBCAUTOCAARCCHECK3183"
    f("CHECKPAYMTRETAIL SERVICES16020").should == "CHECKPAYMTRETAILSERVICES"
  end

  it "should filter trailing dates" do
    first  = "S/LINE 123456789 / SLFIVEWAYS DEN1007"
    second = "S/LINE 123456789 / SLFIVEWAYS DEN3112"
    f(first).should == f(second)
  end

  it "should filter out transaction reference numbers" do
    f("U O Union Staff Club / Eft Pos 503646203457 1918 EFTPOS 02753").should ==
    f("U O Union Staff Club / Eft Pos 503646203457 1918 EFTPOS 02149")
  end

  it "should filter out TD Canada Trust billpay reference numbers" do
    # http://fbz1.dev.oak.wesabe.com/fogbugz/default.php?45580
    f("MTS INTERNET B2Y8W1").should == "MTSINTERNET"
    f("MTS HOME SRV R9J7E9").should == "MTSHOMESRV"
  end

  it "should not filter GMAC check numbers" do
    # http://fbz1.dev.oak.wesabe.com/fogbugz/default.php?48239
    f("Withdrawal / CK#1002").should_not == f("Withdrawal / CK#1003")
  end

  it "should filter out A1 B2 C3 style txaction numbers" do
    f("MTS RES/BUS A7 Z4 D6").should == f("MTS RES/BUS B3 N7 C4")
  end

  it "should filter out Credit Union Mastercard reference numbers" do
    f("FOODLAND IGA             MEDICINE HAT CD / Ref #: 5545945K40Y8X3T1B").should ==
    f("FOODLAND IGA             MEDICINE HAT CD / Ref #: 5545945K20Y8LFRA9")
  end

  it "should filter out months from the end of bill pay items" do
    # http://fbz1.dev.oak.wesabe.com/fogbugz/default.php?52607
    f("TIME WARNER CABLE Aug / Reference# 10195").should ==
    f("TIME WARNER CABLE Sep / Reference# 10196")
  end

  it "should distinguish between Nationwide (UK) transfers" do
    # http://fbz1.dev.oak.wesabe.com/fogbugz/default.php?54662
    f("Transfer to 07-00-40 91503814").should_not ==
    f("Transfer to 0514/631438776")
  end

  it "should filter out RBC Royal Bank (Canada) txaction ids" do
    # http://fbz1.dev.oak.wesabe.com/fogbugz/default.php?59956
    f("NOFRILLS CHRIS / IDP PURCHASE - 5785").should ==
    f("NOFRILLS CHRIS / IDP PURCHASE - 5786")
  end

  it "should distinguish between checks with four-digit numbers" do
    f("POS PURCH CHECK 1006 16:").should_not ==
    f("POS PURCH CHECK 1003 16:")
  end

  it "should distinguish between transfers to different accounts" do
    f("Withdrawal  Internet Transfer to 1000743535").should_not ==
    f("Withdrawal  Internet Transfer to 1000328137")
  end

  it "should filter out Gimli Credit Union trace numbers" do
    f("IQ'S / TRACE # 097170").should ==
    f("IQ'S / TRACE # 098273")
  end

end

def f(string)
  TxactionFilter.filter(string)
end
