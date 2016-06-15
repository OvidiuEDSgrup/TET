--***
/**	functie fDiagnostic CM	*/
Create function  fDiagnostic_CM()
returns @diagnostic_cm table
	(Tip_diagnostic char(2), Denumire char(30))
as
	begin
	insert @diagnostic_cm
	select '0-', 'Ingrij. copil 2 ani' 
	union all 
	select '1-', 'Boala obisnuita'
	union all
	select '2-', 'Acc. depl. munca' 
	union all 
	select '3-', 'Acc. Munca'
	union all
	select '4-', 'Boala profesionala' 
	union all
	select '5-', 'Boala contag.' 
	union all
	select '6-', 'Urgenta med.' 
	union all 
	select '7-', 'Carantina' 
	union all
	select '8-', 'Sarcina,lahuzie' 
	union all
	select '9-', 'Ingrij.copil bolnav' 
	union all
	select '10', 'Red. 1/4 reg.lucru' 
	union all 
	select '11', 'Trecere in alt locm' 
	union all
	select '12', 'Tuberculoza' 
	union all
	select '13', 'Boala cardiov.' 
	union all
	select '14', 'Cancer' 
	union all
	select '15', 'Risc maternal' 

	return 
end
