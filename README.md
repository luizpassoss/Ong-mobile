# Ong Conforme

Projeto realizado com a ideia de desenvolver um software para auxiliar a comunidade de Joinville, em parceria com a Catolica de Santa Catarina.

Disciplina: (PAC) Projeto de Aprendizagem Colaborativa Extensionista do Curso de Engenharia de Software da Católica de Santa Catarina

Docente: Claudinei Dias

Grupo: Cauê Fernandes, João Vitor Ziem e Luiz Fernando Passos.

- [Flutter](https://github.com/flutter/flutter) version 3.24.0.
  
- [MySQL](https://www.mysql.com/) latest version.

## Justificativa do PAC 

A realização deste projeto busca atender às necessidades do Instituto Conforme, uma organização que sem fins lucrativos, que atua na area de assistencia social, apoiando familias e comunidades na regiao de Joinville.

Atualmente, a entidade enfrenta desafios como: dificuldade na gestão de recursos, falta de uma ferramenta centralizada para acompanhamento de atividades ou até uma comunicação ineficiente entre colaboradores e doadores. Esses desafios comprometem o impacto das ações realizadas pela organização e a eficiência operacional, lembrando que a maioria dos colaboradores são voluntários.

O projeto desenvolvido como um Software para Gestão de Estoque, visa resolver essas dificuldades ao oferecer uma solução tecnológica com o intuito de melhorar gestão de tempo, gestão de recursor e aumento da eficiência das operações.

## Como usar 

1. **Abra a pasta** onde você deseja salvar o projeto no VSCode.

2. No terminal, digite:

```bash
git clone https://github.com/luizpassoss/Ong-mobile.git
```
```bash
cd ongconforme
```

### Instalação das dependências

1.  **Instale as dependências do Flutter:**

Para instalar as dependências do Flutter, execute o seguinte comando:

```bash
flutter pub get
```

### Executando o projeto Flutter

1.  **Execute o projeto Flutter:**

Vá para a pasta raiz do projeto e execute o comando:

```bash
flutter run
```

1.  **Acesse o aplicativo** no emulador ou dispositivo conectado. O aplicativo será recarregado automaticamente quando você fizer mudanças no código.

### Executando os testes

Execute
```bash 
flutter test
```
para executar os testes unitários no Flutter.

Para executar testes **end-to-end**, você pode configurar a integração com o Flutter Driver ou usar o integration_test.


```bash 
flutter drive --target=test_driver/app.dart
```

Ou, para usar testes de integração com o `integration_test`:

```bash
flutter test integration_test/app_test.dart
```

Este comando executa os testes end-to-end através do pacote que você escolher.
