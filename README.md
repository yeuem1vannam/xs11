#### Prepare
Create a `config/database.yml` file following
```yaml
development:
  adapter: mysql2
  encoding: utf8
  pool: 5
  username: root
  password:
  socket: #{YOUR_SOCKET_PATH}
  database: xs11
  
development_sqlite:
  adapter: sqlite3
  pool: 5
  timeout: 5000
  database: db/development.sqlite3
```
And create folder `tmp`
#### Crawl!
```bash
$ RAILS_ENV=development_sqlite rake db:create db:migrate
$ rails r "XTeam.regist_new('accprefix')"
```
- `accprefix` will become `accpref` + `("aa".."zz").to_a.rand` + `ix`
- `TeamName` and `CoachName` will be generate random
- Folder `tmp` must be existed before run

#### Serving web
```bash
$ RAILS_ENV=development rake db:create db:migrate
$ rails s
```
