# 감자밭

<img width="30%" src="https://user-images.githubusercontent.com/79244795/157857234-9c106a57-03a0-4fa0-90f3-dda58433da61.PNG">|
<img width="30%" src="https://user-images.githubusercontent.com/79244795/157857224-4a19203f-cb3c-459f-bfa5-bcec75cf5269.PNG">

## [앱스토어에서 보기](https://apps.apple.com/kr/app/%EA%B0%90%EC%9E%90%EB%B0%AD/id1598283026)

## 애플리케이션 소개
고양이의 맛동산, 감자 수를 쉽게 체크하여 기록할 수 있게 만든 애플리케이션입니다.*(사실 고양이가 아니여도 됩니다.)* 

## 프로젝트 기간: 2021.11.15 ~ 2021.12.07 (1.0 출시)

## 프로젝트 진행 방식
기획부터 디자인, 코딩, 서비스까지 개발 프로세스를 경험하며 진행했습니다. *[기획링크](https://github.com/SehunKang/-Scoop-a-day/issues/2)*

## 사용 기술 스택
* Realm
* SnapKit, Charts
* Firebase Analytics, Crashlytics
* Localization

## 프로젝트 진행 일지
* [1일차](https://blog.naver.com/andriy16/222569018090) ~ [17일차](https://blog.naver.com/andriy16/222584369818)

---
## 상세 리뷰, 이슈 및 해결

# Localization
<img width="30%" src="https://user-images.githubusercontent.com/79244795/157873630-b9eda14d-64ed-4a34-b487-fcadafc3caad.png">|
<img width="30%" src="https://user-images.githubusercontent.com/79244795/157873638-47d067e3-a642-43c6-ba76-e5f171e43432.png">|
<img width="30%" src="https://user-images.githubusercontent.com/79244795/157873644-c975f531-f4ee-4556-aa41-c079e8ad6585.png">  
* Localization
  * Localizable.strings 파일을 통해 번역을 하였다. Localization이 번역만 해당하는 것은 아니다. 날짜 표기, 도량형, 미터법, 읽는순서 뿐 아니라 서비스의 현지화를 위한 많은 분야가 있다. 하지만 감자밭에서는 
  하지만 특별히 적용할 만한 내용이 없어 번역만 하였다.
  * WWDC를 보며 카탈로그를 export, import 하는 등의 팀 단위에서의 다양한 로컬라이징 방법들이 있음을 확인했지만 내 프로젝트에 적용할 방법까지 학습하진 못했다.

# DB
* Realm
  * Realm을 사용하여 고양이의 배변 데이터를 저장한다. 
  * 싱글턴 패턴을 활용한 RealmService 클래스를 만들어 CRUD를 구현하였다.

# Dark Mode
* Dark Mode
  * iOS 13 이상의 버전을 서비스하는 앱이라면 다크모드는 필수라고 생각하여 기획단계에서부터 학습과 구현을 기획했다.   
  * 텍스트나 배경화면같은 UI의 색은 semantic color로 쉽게 해결할 수 있었지만 에셋같은 경우 조금 애를 먹었다. Shutterstock에서 찾은 이미지로 총 7가지 고양이 이미지를 만들었지만 
  다크모드의 경우 색상 반전을 통해 적절하게 넣을만한 에셋이 없어 2가지밖에 넣지 못했다. 
  혼자 애플리케이션을 만들며 가장 어려웠던 부분이 이런 부분이었다. 디자인을 하는것부터가 막막했고 맘에 드는 에셋을 찾고 만드는건 더 어려웠다.
  
일반 고양이
<img width="10%" src="https://user-images.githubusercontent.com/79244795/157877534-1a40fbeb-db3c-4852-a596-fc433233bdf6.png">|
<img width="10%" src="https://user-images.githubusercontent.com/79244795/157877558-e25b0cd0-b0a9-4ded-978d-92651f627bed.png">|
<img width="10%" src="https://user-images.githubusercontent.com/79244795/157877580-7a59c025-8681-4c2d-a206-fc10ab8b3c80.png">|
<img width="10%" src="https://user-images.githubusercontent.com/79244795/157877608-2bc2a19f-ac43-46f5-a36c-452a6c7dff08.png">|
<img width="10%" src="https://user-images.githubusercontent.com/79244795/157877625-eeb5e577-38d0-42ff-bf26-715bd9198db1.png">|
<img width="10%" src="https://user-images.githubusercontent.com/79244795/157877642-e9230718-76ab-4f67-bd8b-394f4adc0b01.png">|
<img width="10%" src="https://user-images.githubusercontent.com/79244795/157877659-5ff11ba2-4d57-4a5d-a92b-f2711fcb2934.png">  

다크모드 고양이
<img width="5%" src="https://user-images.githubusercontent.com/79244795/157877733-0489e46d-f807-4224-833f-d3f19767db88.png">|
<img width="5%" src="https://user-images.githubusercontent.com/79244795/157877755-eef3e881-af54-426a-ba7c-2e93ec1c0421.png">  

# Charts
<img width="30%" src="https://user-images.githubusercontent.com/79244795/157857224-4a19203f-cb3c-459f-bfa5-bcec75cf5269.PNG">  

* Charts 라이브러리를 활용해 DB에 저장되어있는 배변 데이터를 보여준다.  
* UIPickerView를 활용해 DB에 있는 데이터만큼 연, 월을 선택할 수 있는데 이 부분에서 이슈가 있었다. DB에 일 단위로 저장되는 데이터들의 Date는 UTC 기준으로 저장이 된다. 피커뷰를 설정하기 위해
  시작일과 끝일 즉 두가지 Date를 매개변수로 받아 그 사이 존재하는 연도를 나타내는 Date의 배열, 월을 나타내는 Date의 배열을 리턴하는 메서드를 만들어 활용했다.  
  여기서 오류가 생겼는데, 만약 한국인 사용자가 11월 30일, 12월 1일 배변 데이터를 입력하면 DB에는 UTC기준 11월 29, 11월 30으로 입력되고 그러면 해당 메서드를 사용했을 때
  11월 한달에 해당하는 1개의 Date만 리턴한다. 12월 2일이 되어야 피커뷰에 11월, 12월 두 데이터를 선택할 수 있게 되는 것이다. 처음 Date가 UTC 기준으로 설정되는 것을 이해하지 못해 해당 이슈가
  왜 생기는 지를 찾는데만 많은 시간을 쏟았다.  
  * 해당 메서드에 매개변수로 전달하는 Date값을 다시한번 정제하는 방법으로 해결했다.  
  
# 심사
## 총 2번의 리젝을 당했다.
<img width="100%" src="https://user-images.githubusercontent.com/79244795/157886737-6e7dfb51-ec98-4a32-a2fd-235b8070e692.png">  
  
* 리젝사유 1
  * 첫 리젝은 애플리케이션 이름을 제대로 설정해주지 않아서였는데 애플리케이션 이름도 따로 로컬라이징 해야한다는걸 몰랐었다. infoPlist파일을 생성하여 Localization설정을 해줘야한다. 앱 이름같은
  경우는 CFBUndleDisplayName 으로 설정.  
    
    
<img width="100%" src="https://user-images.githubusercontent.com/79244795/157886762-80c5f643-ba57-4c1d-a69e-5bbbd6feff60.png">   

* 리젝사유 2  
  * 두번째 리젝은 설정을 다 고쳐놓고 앱스토어에 배포하는 과정에서, 아카이빙이 실패한 상태로 심사를 넣어 리젝을 받았던 버전이 다시 심사에 들어가 생긴 경우였다.  


