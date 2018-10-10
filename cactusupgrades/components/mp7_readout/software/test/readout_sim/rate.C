#include <iostream>
#include <algorithm>
#include "TRandom2.h"
#include "TH1.h"
#include "TFile.h"

#define TRIG_RATE_DIVISOR (40000.0 / 200.0)
#define N_BX 1000000000LL
#define TRIG_NORM_DATA_LEN 1500
#define TRIG_DEBUG_DIVISOR 107
#define TRIG_DEBUG_DATA_LEN 1500
#define RBUF_SIZE 32768
#define RBUF_HWM (RBUF_SIZE / 2)
#define RBUF_LWM (RBUF_SIZE / 4)
#define TTS_LATENCY 20

long long int next_trig(long long int);

int main(){

	TH1I hdql("dql", "Derand queue length", 100, 0.0, 50000.0);
	TH1I hrql("rql", "Readout queue length", 100, 0.0, 50000.0);
	TFile f("out.root", "RECREATE");
	
	bool stop = false;
	long long int ibx = 0;
	int dql = 0;
	int rql = 0;
	bool tts_throttle = true;
	bool throttle = false;
	long long int dead = 0;
	long long int sim = 0;
	long long int odata = 0;
	long long int ntrig = 0;
	long long int next_trig_bx = 0;
	long long int next_throttle_bx = 0;
	long long int last_throttle_bx = 0;
	
	while(ibx < N_BX){
		if(ibx == next_throttle_bx){
			next_throttle_bx = 0;
			tts_throttle = throttle;
		}
		if(ibx == next_trig_bx){	
			next_trig_bx = next_trig(ibx);
			if(!tts_throttle){
				dql += ibx % TRIG_DEBUG_DIVISOR == 0 ? TRIG_DEBUG_DATA_LEN : TRIG_NORM_DATA_LEN;
				ntrig += 1;
			}
		}
		if(dql > 0){
			int l = std::min(dql, 6);
			dql -= l;
			rql += l;
		}
		if(rql > 0){
			int l = std::min(rql, 3);
			rql -= l;
			odata += l;
			if((rql > RBUF_HWM && !throttle) || (rql < RBUF_LWM && throttle)){
				if(throttle) dead += ibx - last_throttle_bx;
				else last_throttle_bx = ibx;
				throttle = !throttle;
				next_throttle_bx = ibx + TTS_LATENCY;
			}
			if(rql > RBUF_SIZE){
				std::cout << "Game over - out of sync" << std::endl;
				stop = true;
			}
		}
		hdql.Fill(dql);
		hrql.Fill(rql);
		if(stop) break;
		if(dql != 0 || rql != 0){
			ibx++;
		}
		else ibx = ((next_throttle_bx == 0) ? next_trig_bx : std::min(next_trig_bx, next_throttle_bx));
		sim++;
	}
	
	hdql.Write();
	hrql.Write();
	f.Close();
	
	std::cout << "Simulated: " << sim << " from " << ibx << " (" << 100.0 * float(sim) / float(ibx) << "%)" << std::endl;
	std::cout << "Triggers: " << ntrig << " (" << (40 * 1000 * double(ntrig) / ibx) << "kHz)" << std::endl;
	std::cout << "Data: " << odata << " (" << (32 * double(odata) / (1024 * 1024 * 1024)) / (25.0E-9 * ibx) << "Gb/s)" << std::endl;
	std::cout << "Dead time: " << dead << " (" << 100.0 * float(dead) / float(ibx) << "%)" << std::endl;

	return 0;
}

long long int next_trig(long long int ibx){
	static TRandom2 rnd;
	static long long int h[4] = {0, 0, 0, 0};
	long long int bx = ibx;
	while(true){
		bx += int(rnd.Exp(TRIG_RATE_DIVISOR));
		if(bx - h[0] < 3) continue;
		if(bx - h[1] < 25) continue;
		if(bx - h[2] < 100) continue;
		if(bx - h[3] < 240) continue;
		break;
	}
	for(int i = 3; i > 0; i--) h[i] = h[i - 1];
	h[0] = bx;
	return bx;
}
