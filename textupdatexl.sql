select * from testerrxls

update testerrxls
set _eroareimport=REPLACE(_eroareimport,'!','')

UPDATE x 
		SET _eroareimport = 'testerr'--e._eroareimport
		from OPENROWSET('Microsoft.ACE.OLEDB.12.0'
		,'Excel 12.0;Database=\\10.0.0.10\import\testimport.xlsx;Extended Properties="Excel 12.0 Xml;IMEX=0;HDR=YES;";'
		, 'Select * from [nomencl$]') x  
		--inner join testerrxls e on e._linieimport=x._linieimport
		where x._linieimport=357
		
UPDATE x 
		SET _eroareimport = 'testerr'--e._eroareimport
		from opendatasource('Microsoft.ACE.OLEDB.12.0'
		,'Data Source=\\10.0.0.10\import\testimport.xlsx;Extended Properties="Excel 12.0 Xml;IMEX=0;HDR=YES;";')...[nomencl$] x  
		--inner join testerrxls e on e._linieimport=x._linieimport
		where x.[_linieimport]=357
		