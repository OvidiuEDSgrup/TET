--exec corectiiDocument @data='2016-01-21',@datalunii='2016-01-01'

select * from sys.sql_modules m 
where m.definition like '%corectiiDocument%'