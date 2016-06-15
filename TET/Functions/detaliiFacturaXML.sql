--***
create function detaliiFacturaXML (@iDoc int)
returns @docxml table
(
	IDPartener char(20), DenumireFurnizor char(80), Factura char(20), DataFact datetime, DataScad datetime, 
	Cod char(20), Denumire char(100), Cantitate float, Valuta char(3), PretValuta float, Discount float, PretVanzare float, 
	CotaTVA float, SumaTVA float, ComAprov char(20), CodBare char(20), CodSpec char(20), UM char(3), UM2 char(3), Cantitate2 float
)
begin

insert @docxml
select a.IDPartener, a.DenFurnizor, a.Factura, a.DataFact, a.DataScad, 
a.Cod, a.Denumire, a.Cantitate, a.Valuta, a.PretValuta, a.Discount, a.PretVanzare, 
a.CotaTVA, a.SumaTVA, a.ComAprov, a.CodBare, a.CodSpec, a.UM, a.UM2, a.Cantitate2
from OPENXML(@iDoc, 'Document/Pozitii/pozitie', 1)
WITH 
(	
	IDPartener varchar(20) '../../Antet/@IDPartener', 
	DenFurnizor varchar(80) '../../Antet/@DenFurnizor', 
	Factura varchar(20) '../../Antet/@Factura', 
	DataFact datetime '../../Antet/@Data', 
	DataScad datetime '../../Antet/@Data_scadentei', 
	Cod varchar(20) '@Cod', 
	Denumire varchar(80) '@Denumire', 
	Cantitate float '@Cantitate', 
	Valuta varchar(3) '@Valuta', 
	PretValuta float '@PretLista', 
	Discount float '@Discount', 
	PretVanzare float '@PretVanzare', 
	CotaTVA float '@CotaTVA', 
	SumaTVA float '@TVA', 
	ComAprov varchar(20) '@Comanda', 
	CodBare varchar(20) '@CodBare', 
	CodSpec varchar(20) '@CodSpec', 
	UM varchar(3) '@UM', 
	UM2 varchar(3) '@UM2', 
	Cantitate2 float '@CantitateUM2' 
) a

return 
end
