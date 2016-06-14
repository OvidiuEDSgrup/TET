declare @user varchar(15)
set @user='ASIS\craiova-01'

SELECT u.bd bd, b.nume nume, b.poza poza, b.detalii detalii 
FROM ASiSria.dbo.utilizatoriRIA u INNER JOIN ASiSria.dbo.bazedeDateRIA b ON u.bd = b.bd 
WHERE u.utilizatorWindows = @user ORDER BY b.nume FOR XML RAW,ROOT('Date')

select * from utilizatoriRIA

insert into utilizatoriRIA
select 'TEST',	'MAGAZIN_DJ','',		'ASIS\craiova-01',	NULL