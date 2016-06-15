--***
create procedure wScriuPozSalarii  @sesiune varchar(50), @parXML xml 
as
begin

declare @subtip varchar(2)
Select @subtip=xA.row.value('@subtip', 'char(2)') from @parXML.nodes('row/row') as xA(row)

if @subtip in ('A1','A2')
	exec wScriuAvexcep @sesiune, @parXML
else if @subtip in ('M1','M2')
	exec wScriuConmed @sesiune, @parXML
else if @subtip in ('O1','O2')
	exec wScriuConcodih @sesiune, @parXML
else if @subtip in ('P1','P2','S1','S2')
	exec wScriuPontaj @sesiune, @parXML
else if @subtip in ('C1','C2','C3','C4')
	exec wScriuCorectii @sesiune, @parXML
else if @subtip in ('R1','R2')
	exec wScriuResal @sesiune, @parXML
else if @subtip in ('T1','T2')
	exec wScriuTichete @sesiune, @parXML
else if @subtip in ('E1','E2')
	exec wScriuConalte @sesiune, @parXML
else 
	select '1' as coderoare, 'Tip incorect' as msgeroare for xml raw
end
