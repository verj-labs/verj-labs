import Link from "next/link";
import { 
  Home, 
  ArrowRight, 
  Compass, 
  Map,
  Search,
  Mail,
  Sparkles
} from "lucide-react";

export default function NotFound() {
  return (
    <div className="min-h-screen flex items-center justify-center relative overflow-hidden">
      {/* Background Elements */}
      <div className="absolute inset-0 pointer-events-none">
        {/* Decorative Shapes */}
        <div className="decorative-shape decorative-circle w-96 h-96 bg-gradient-to-r from-verj-violet to-verj-blue top-10 right-20 animate-pulse-slow" />
        <div className="decorative-shape decorative-blob w-64 h-64 bg-gradient-to-r from-verj-coral to-verj-green bottom-20 left-20 animate-float" />
        <div className="decorative-shape decorative-rounded w-48 h-48 bg-gradient-to-r from-verj-blue to-verj-violet top-1/3 left-1/4 animate-gentle-bounce" />
        
        {/* Floating Numbers */}
        <div className="absolute top-20 left-20 text-9xl font-bold text-verj-violet/5 animate-rotate-slow">4</div>
        <div className="absolute bottom-32 right-32 text-8xl font-bold text-verj-blue/5 animate-scale-pulse">0</div>
        <div className="absolute top-1/2 right-20 text-7xl font-bold text-verj-coral/5 animate-float">4</div>
      </div>
      
      <div className="max-w-4xl mx-auto px-6 text-center relative z-10">
        {/* Main 404 Graphic */}
        <div className="mb-12 animate-fade-in">
          <div className="relative inline-block">
            {/* Large 404 with gradient shapes */}
            <div className="text-9xl md:text-[12rem] lg:text-[16rem] font-bold font-poppins relative">
              {/* First 4 */}
              <span className="relative inline-block">
                <span className="text-transparent bg-clip-text bg-gradient-to-br from-verj-violet to-verj-blue">4</span>
                <div className="absolute inset-0 bg-gradient-to-br from-verj-violet/20 to-verj-blue/20 blur-xl"></div>
              </span>
              
              {/* 0 */}
              <span className="relative inline-block mx-4">
                <span className="text-transparent bg-clip-text bg-gradient-to-br from-verj-coral to-verj-green">0</span>
                <div className="absolute inset-0 bg-gradient-to-br from-verj-coral/20 to-verj-green/20 blur-xl"></div>
              </span>
              
              {/* Second 4 */}
              <span className="relative inline-block">
                <span className="text-transparent bg-clip-text bg-gradient-to-br from-verj-blue to-verj-violet">4</span>
                <div className="absolute inset-0 bg-gradient-to-br from-verj-blue/20 to-verj-violet/20 blur-xl"></div>
              </span>
            </div>
            
            {/* Decorative elements around 404 */}
            <div className="absolute -top-8 -right-8 animate-gentle-bounce">
              <div className="w-16 h-16 shape-circle bg-gradient-to-r from-verj-violet to-verj-blue opacity-80" />
            </div>
            <div className="absolute -bottom-8 -left-8 animate-float">
              <div className="w-12 h-12 shape-rounded bg-gradient-to-r from-verj-coral to-verj-green opacity-80" />
            </div>
            <div className="absolute top-1/2 -right-12 animate-scale-pulse">
              <Sparkles className="text-verj-violet w-8 h-8" />
            </div>
          </div>
        </div>
        
        {/* Error Message */}
        <div className="mb-12 animate-slide-up animate-stagger-2">
          <h1 className="text-4xl md:text-5xl font-bold text-white font-poppins mb-6">
            Oops! We couldn't find that page.
          </h1>
          <p className="text-xl md:text-2xl text-verj-muted max-w-2xl mx-auto leading-relaxed font-lato">
            The page you're looking for might have been removed, renamed, or is temporarily unavailable.
            Don't worry — let's get you back on track.
          </p>
        </div>
        
        {/* Lost Astronaut Illustration */}
        <div className="mb-12 animate-slide-up animate-stagger-3">
          <div className="relative inline-block">
            <div className="bento-card bento-card-medium max-w-md mx-auto">
              <div className="flex items-center justify-center space-x-4 text-6xl">
                <Compass className="text-verj-coral animate-rotate-slow" size={64} />
                <Map className="text-verj-blue animate-gentle-bounce" size={56} />
              </div>
              <p className="text-verj-muted mt-4 text-sm">
                Even our compass seems a bit confused...
              </p>
            </div>
          </div>
        </div>
        
        {/* Action Buttons */}
        <div className="flex flex-col sm:flex-row gap-6 justify-center items-center mb-12 animate-slide-up animate-stagger-4">
          {/* Primary Button - Go Home */}
          <Link 
            href="/" 
            className="btn-primary text-lg px-10 py-5 group bg-verj-violet hover:bg-verj-violet/90"
          >
            <Home className="mr-2 group-hover:scale-110 transition-transform" size={20} />
            <span>Go to Home</span>
          </Link>
          
          {/* Secondary Button - Search */}
          <Link 
            href="/products" 
            className="border-2 border-verj-blue text-verj-blue px-10 py-5 rounded-2xl font-semibold text-lg hover:bg-verj-blue hover:text-white transition-all duration-300 flex items-center space-x-2 group"
          >
            <Search className="group-hover:scale-110 transition-transform" size={18} />
            <span>Browse Our Products</span>
          </Link>
        </div>
        
        {/* Quick Links */}
        <div className="animate-slide-up animate-stagger-5">
          <p className="text-verj-muted mb-6">Or explore these popular sections:</p>
          <div className="flex flex-wrap justify-center gap-4">
            <Link 
              href="/about" 
              className="inline-flex items-center space-x-2 text-verj-blue hover:text-verj-violet transition-colors px-4 py-2 rounded-lg hover:bg-verj-violet/10"
            >
              <span>About Us</span>
              <ArrowRight size={16} />
            </Link>
            <Link 
              href="/services" 
              className="inline-flex items-center space-x-2 text-verj-blue hover:text-verj-violet transition-colors px-4 py-2 rounded-lg hover:bg-verj-violet/10"
            >
              <span>Our Services</span>
              <ArrowRight size={16} />
            </Link>
            <Link 
              href="/contact" 
              className="inline-flex items-center space-x-2 text-verj-blue hover:text-verj-violet transition-colors px-4 py-2 rounded-lg hover:bg-verj-violet/10"
            >
              <Mail size={16} />
              <span>Contact</span>
              <ArrowRight size={16} />
            </Link>
          </div>
        </div>
      </div>
      
      {/* Bottom gradient overlay */}
      <div className="absolute bottom-0 inset-x-0 h-32 bg-gradient-to-t from-verj-navy/50 to-transparent pointer-events-none" />
    </div>
  );
}
