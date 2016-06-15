create proc yso_xIaTargetag as
select 
Agent
, Denumire_agent
, Client
, Denumire_client
, Pct_livr
, Grupa_produs
, Denumire_grupa
, Data_lunii
, Cantitate_valoare from yso_vIaTargetag
