(@eroareimport varchar(500))UPDATE x SET _eroareimport = @eroareimport from OPENROWSET('Microsoft.ACE.OLEDB.12.0', 'Excel 12.0;Database=\\10.0.0.10\IMPORT\testimport.xlsx ;Extended Properties="Excel 12.0 Xml;IMEX=1;HDR=YES;";', 'Select * from [tehn$]') x 